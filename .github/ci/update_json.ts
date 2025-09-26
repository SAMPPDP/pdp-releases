import { createHash } from 'crypto'
import { readFile } from 'fs/promises'
import { join } from 'path'

async function calculateSHA1(filePath: string): Promise<string> {
    try {
        const fileContent = await readFile(filePath)
        const hash = createHash('sha1')
        hash.update(fileContent)
        return hash.digest('hex')
    } catch (error) {
        console.error(`Error reading file: ${error}`)
        throw error
    }
}

async function main() {
    console.log('Bun started.')

    const filename = 'Radio1.mp3'
    const filePath = join(import.meta.dir, filename)
    console.log(`Full path: ${filePath}`)

    try {
        const sha1Hash = await calculateSHA1(filePath)
        console.log(`SHA1 hash of ${filename}: ${sha1Hash}`)
    } catch (err) {
        console.error('Error calculating SHA1 hash: ', err)
        process.exit(1)
    }
}

main()
