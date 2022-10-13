import { RouteControllerMap } from 'openapi-enforcer-middleware'
import { Request, Response } from 'express'
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from '@aws-sdk/lib-dynamodb'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'

const client = new DynamoDBClient({
  region: process.env.AWS_REGION, // 'us-west-2',
  endpoint: process.env.DYNAMODB_ENDPOINT // set the DYNAMODB_ENDPOINT to http://localhost:8000 when using local dynamo
})

const ddbDocClient = DynamoDBDocumentClient.from(client)

export default function (tableName: string): RouteControllerMap {
  return {
    async listFavoriteColors (req: Request, res: Response) {
      const output = await ddbDocClient.send(
        new ScanCommand({
          TableName: 'sg738-fav-color-dev', // sg738-fav-color
          AttributesToGet: ['byuId', 'favoriteColor', 'name']
        })
      )
      if (output.Items !== undefined) {
        const items = output.Items
        res.enforcer?.send(items)
      } else {
        res.enforcer?.send([{}])
      }
    },
    async addFavoriteColor (req: Request, res: Response) {
      const userFavoriteColor: string = req.enforcer?.body.favoriteColor
      const byuId: string = req.enforcer?.body.byuId
      const name: string = req.enforcer?.body.name
      await ddbDocClient.send(
        new PutCommand({
          TableName: 'sg738-fav-color-dev', // sg738-fav-color
          Item: {
            byuId: byuId,
            favoriteColor: userFavoriteColor,
            name: name
          }
        })
      )
      res.enforcer?.send({
        result: 'Item successfully added to database.'
      })
    }
  }
}
