import { randomUUID } from 'node:crypto'
import { exportUploads } from '@/app/functions/export-uploads'
import * as uploads from '@/infra/storage/upload-file-to-storage'
import { isRight, unwrapEither } from '@/shared/either'
import { makeUpload } from '@/test/factories/make-upload'
import { describe, expect, it, vi } from 'vitest'

describe('export uploads', () => {
  it('should be able to export uploads', async () => {
    const uploadCSVStub = vi
      .spyOn(uploads, 'uploadFileToStorage')
      .mockImplementationOnce(async () => {
        return {
          key: `${randomUUID()}.csv`,
          url: `http://example.com/${randomUUID()}.csv`,
        }
      })

    const namePattern = randomUUID()

    const upload1 = await makeUpload({ name: `${namePattern}.wep` })
    const upload2 = await makeUpload({ name: `${namePattern}.wep` })
    const upload3 = await makeUpload({ name: `${namePattern}.wep` })
    const upload4 = await makeUpload({ name: `${namePattern}.wep` })
    const upload5 = await makeUpload({ name: `${namePattern}.wep` })

    const sut = await exportUploads({
      searchQuery: namePattern,
    })

    const generatedCSVStream = uploadCSVStub.mock.calls[0][0].contentStream
    const csvAsString = await new Promise<string>((resolve, reject) => {
      const chunks: Buffer[] = []

      generatedCSVStream.on('data', (chunk: Buffer) => {
        chunks.push(chunk)
      })

      generatedCSVStream.on('end', () => {
        resolve(Buffer.concat(chunks).toString('utf-8'))
      })

      generatedCSVStream.on('error', err => {
        reject(err)
      })
    })
    const csvAsArray = csvAsString
      .trim()
      .split('\n')
      .map(line => line.split(','))
    expect(isRight(sut)).toBe(true)
    expect(unwrapEither(sut)).toEqual({
      reportUrl: expect.stringContaining('http://example.com'),
    })
    expect(csvAsArray).toEqual([
      ['ID', 'Name', 'URL', 'Uploaded at'],
      [upload1.id, upload1.name, upload1.remoteUrl, expect.any(String)],
      [upload2.id, upload2.name, upload2.remoteUrl, expect.any(String)],
      [upload3.id, upload3.name, upload3.remoteUrl, expect.any(String)],
      [upload4.id, upload4.name, upload4.remoteUrl, expect.any(String)],
      [upload5.id, upload5.name, upload5.remoteUrl, expect.any(String)],
    ])
  })
})
