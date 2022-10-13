import server from '../src/server'
import request from 'supertest'
import { Application } from 'express'

let app: Application

beforeAll(async () => {
  app = await server('')
})

describe('GET /health', () => {
  test('should return 200', async () => {
    const response = await request(app).get('/health')
    expect(response.statusCode).toBe(200)
  })
})
