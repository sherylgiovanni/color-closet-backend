import { RouteControllerMap } from 'openapi-enforcer-middleware'
import { Request, Response } from 'express'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, GetCommand, UpdateCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb'

const client = new DynamoDBClient({
  region: process.env.AWS_REGION, // 'us-west-2',
  endpoint: process.env.DYNAMODB_ENDPOINT // set the DYNAMODB_ENDPOINT to http://localhost:8000 when using local dynamo
})

const ddbDocClient = DynamoDBDocumentClient.from(client)

export default function (tableName: string): RouteControllerMap {
  return {
    async getFavoriteColor (req: Request, res: Response) {
      const id = req.enforcer?.params.byuId
      const output = await ddbDocClient.send(
        new GetCommand({
          TableName: 'sg738-fav-color-dev',
          Key: {
            byuId: id
          }
        })
      )
      if (output.Item !== undefined) {
        const color = output.Item.favoriteColor
        const name = output.Item.name
        res.enforcer?.send({
          favoriteColor: color,
          name: name
        })
      } else {
        res.enforcer?.send({
          message: 'ID not found. Please check and try again.'
        })
      }
    },
    async updateFavoriteColor (req: Request, res: Response) {
      const id = req.enforcer?.params.byuId
      const favoriteColor = req.enforcer?.body.favoriteColor
      await ddbDocClient.send(
        new UpdateCommand({
          TableName: 'sg738-fav-color-dev',
          Key: {
            byuId: id
          },
          UpdateExpression: 'set favoriteColor = :favoriteColor',
          ExpressionAttributeValues: {
            ':favoriteColor': favoriteColor
          }
        })
      )
      res.status(200).enforcer?.send({
        result: 'Item successfully updated.'
      })
    },
    async removeFavoriteColor (req: Request, res: Response) {
      const id = req.enforcer?.params.byuId
      const output = await ddbDocClient.send(
        new DeleteCommand({
          TableName: 'sg738-fav-color-dev',
          Key: {
            byuId: id
          }
        })
      )
      if (output.ConsumedCapacity === undefined) {
        res.status(200).enforcer?.send({
          result: 'Item successfully deleted.'
        })
      } else {
        res.status(200).enforcer?.send({
          result: 'ID can not be found'
        })
      }
    }
  }
}
