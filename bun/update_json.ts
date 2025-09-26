import { createHash } from 'crypto'
import { readFile, writeFile, readdir, stat, access } from 'fs/promises'
import { join, resolve, basename, relative } from 'path'
import { constants } from 'fs'

interface ScriptJson {
    timestamp: number
    filename: string
    sha1: string
    raw: string
}

interface TreeFile {
    type: 'file'
    name: string
    sha1: string
    raw: string
}

interface TreeDir {
    type: 'dir'
    name: string
    tree: Tree[]
}

type Tree = TreeFile | TreeDir

const projectPath = resolve(import.meta.dir, '..') // remove dir bun
const uploadPath = join(projectPath, 'upload')

const args = process.argv.slice(2)
const repositoryArg = args.find(arg => arg.startsWith('repository='))
const branchArg = args.find(arg => arg.startsWith('branch='))
const filenameArg = args.find(arg => arg.startsWith('filename='))

const repository = repositoryArg ? repositoryArg.split('=')[1] : null
const branch = branchArg ? branchArg.split('=')[1] : null
const filename = filenameArg ? filenameArg.split('=')[1] : null

function getSha1SumsFromTree(tree: Tree[]): string[] {
    let sha1Sums: string[] = []

    for (const node of tree) {
        if (node.type === 'file') {
            sha1Sums.push(node.sha1)
        } else if (node.type === 'dir') {
            sha1Sums = sha1Sums.concat(getSha1SumsFromTree(node.tree))
        }
    }

    return sha1Sums
}

function areSha1SumsEqual(arr1: string[], arr2: string[]): boolean {
    if (arr1.length !== arr2.length) {
        return false
    }

    arr1.sort()
    arr2.sort()

    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] !== arr2[i]) {
            return false
        }
    }

    return true
}

async function calculateSHA1(filePath: string): Promise<string> {
    try {
        const fileContent = await readFile(filePath)
        const hash = createHash('sha1')
        hash.update(fileContent)
        return hash.digest('hex')
    } catch (err) {
        console.error('Error calculating SHA1 hash: ', err)
        throw err
    }
}

async function createFileJson(filePath: string, filename: string): Promise<void> {
    try {
        const sha1 = await calculateSHA1(filePath)
        const relativePath = relative(projectPath, filePath).replace(/\\/g, '/')
        const raw = `https://raw.githubusercontent.com/${repository}/${branch}/${relativePath}`

        const scriptJson: ScriptJson = {
            timestamp: Date.now(),
            filename: filename,
            sha1: sha1,
            raw: raw,
        }

        const scriptJsonPath = join(uploadPath, 'script.json')
        let existingScriptJson: ScriptJson | null = null
        try {
            await access(scriptJsonPath, constants.F_OK)
            const existingContent = await readFile(scriptJsonPath, 'utf-8')
            existingScriptJson = JSON.parse(existingContent) as ScriptJson
        } catch (err) {
            // File doesn't exist, so it will be created
            console.log('>> script.json does not exist.  Creating...')
        }

        if (
            existingScriptJson && existingScriptJson.sha1 === scriptJson.sha1 &&
            existingScriptJson.filename === scriptJson.filename
        ) {
            console.log('>> script.json: SHA1 and filename match.  No change needed.')
            return
        } else {
            console.log('>> script.json: File content changed.  Updating...')
        }

        await writeFile(scriptJsonPath, JSON.stringify(scriptJson, null, 2))
        console.log('>> Created/updated script.json:', scriptJsonPath)

    } catch (err) {
        console.error('>> Error creating/updating script.json:', err)
        throw err
    }
}

async function createFolderJson(folderPath: string, filename: string): Promise<void> {
    try {
        const treeData = await buildTree(folderPath)

        const folderJson = {
            timestamp: Date.now(),
            data: treeData,
        }

        const folderJsonPath = join(uploadPath, filename)
        let existingFolderJson: { timestamp: number, data: Tree[] } | null = null
        try {
            await access(folderJsonPath, constants.F_OK)
            const existingContent = await readFile(folderJsonPath, 'utf-8')
            existingFolderJson = JSON.parse(existingContent) as { timestamp: number, data: Tree[] }
        } catch (err) {
            console.log(`>> ${filename} does not exist.  Creating...`)
        }

        const currentSha1Sums = getSha1SumsFromTree(treeData)
        const existingSha1Sums = existingFolderJson ? getSha1SumsFromTree(existingFolderJson.data) : []

        if (existingFolderJson && areSha1SumsEqual(currentSha1Sums, existingSha1Sums)) {
            console.log(`>> ${filename}: SHA1 match.  No change needed.`)
            return // No changes required
        } else {
            console.log(`>> ${filename}: File content changed.  Updating...`)
        }

        await writeFile(folderJsonPath, JSON.stringify(folderJson, null, 2))
        console.log(`>> Created/updated ${filename}: ${folderJsonPath}`)

    } catch (error) {
        console.error(`>> Error creating/updating ${filename}: ${error}`)
        throw error
    }
}

async function buildTree(dirPath: string): Promise<Tree[]> {
    const files = await readdir(dirPath)
    const tree: Tree[] = []

    for (const file of files) {
        const filePath = join(dirPath, file)
        const stats = await stat(filePath)
        const name = basename(file)

        if (stats.isFile()) {
            const sha1 = await calculateSHA1(filePath)
            const relativePath = relative(projectPath, filePath).replace(/\\/g, '/')
            const raw = `https://raw.githubusercontent.com/${repository}/${branch}/${relativePath}`

            tree.push({
                type: 'file',
                name: name,
                sha1: sha1,
                raw: raw,
            })
        } else if (stats.isDirectory()) {
            const subtree = await buildTree(filePath)
            tree.push({
                type: 'dir',
                name: name,
                tree: subtree,
            })
        }
    }

    return tree
}

async function main() {
    if (!filename) {
        console.error('Missing filename argument')
        process.exit(1)
    }

    const filePath = join(uploadPath, filename)
    const uploadLibPath = join(uploadPath, 'lib')
    const uploadResourcePath = join(uploadPath, 'resource')

    try {
        await createFileJson(filePath, filename)
        await createFolderJson(uploadLibPath, 'lib.json')
        await createFolderJson(uploadResourcePath, 'resource.json')
        console.log('All JSON files created successfully.')
    } catch (error) {
        console.error('An error occurred:', error)
        process.exit(1)
    }
}

main()
