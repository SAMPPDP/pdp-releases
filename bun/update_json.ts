import { createHash } from 'crypto'
import { readFile } from 'fs/promises'
import { resolve } from 'path'

async function calculateSHA1(filePath: string): Promise<string> {
    try {
        const fileContent = await readFile(filePath)
        const hash = createHash('sha1')
        hash.update(fileContent)
        return hash.digest('hex')
    } catch (error) {
        console.error(`Error reading file: ${error}`)
        console.error('Script will now exit due to error.')
        process.exit(1)
    }
}

async function main() {
    const args = process.argv.slice(2) // slice(2) to skip 'bun' and 'path_script'
    const repositoryArg = args.find(arg => arg.startsWith('repository='))
    const branchArg = args.find(arg => arg.startsWith('branch='))
    const filenameArg = args.find(arg => arg.startsWith('filename='))

    const repository = repositoryArg ? repositoryArg.split('=')[1] : null
    const branch = branchArg ? branchArg.split('=')[1] : null
    const filename = filenameArg ? filenameArg.split('=')[1] : null

    if (!repository || !branch || !filename) {
        console.error('Missing required arguments: repository, branch, or filename')
        console.error('Usage: bun run script.ts repository=... branch=... filename=...')
        process.exit(1)
    }

    console.log(`Repository: ${repository}`)
    console.log(`Branch: ${branch}`)
    console.log(`Filename: ${filename}`)

    const filePath = resolve(import.meta.dir, '..', 'upload', filename)

    console.log(`Attempting to read file from: ${filePath}`)

    try {
        const sha1Hash = await calculateSHA1(filePath)
        console.log(`SHA1 hash of ${filename}: ${sha1Hash}`)
    } catch (error) {
        console.error(`Error calculating SHA1 hash: ${error}`)
        console.error('Script will now exit due to error.')
        process.exit(1)
    }
}

main()
