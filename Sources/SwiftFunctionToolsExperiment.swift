// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import JSONSchema
import JSONSchemaBuilder
import SwiftDotenv
import OpenAI

let weatherSchema = JSONObject {
  JSONProperty(key: "location") {
    JSONString()
      .description("The city")
  }
  .required()
}

func weather(location: String) async -> String {
  print("Hello from weather")
  print("Mocking call for \(location)")
  return "Here's the weather in Paris: 32°C"
}

@Schemable
struct DeliveryLookupData {
  @SchemaOptions(description: "The customer's order ID.")
  let orderID: String
}

func deliveryDate(_ lookupData: DeliveryLookupData) async -> String {
  print("Hello from deliveryDate")
  print("Mocking call for \(lookupData.orderID)")
  return "Delivery date: 2021-01-15"
}

@main
struct SwiftFunctionToolsExperiment: AsyncParsableCommand {
  @Argument
  var text: String

  mutating func run() async throws {
    try Dotenv.configure()

    var service = GPTService(apiKey: Dotenv.openaiKey!.stringValue)

    service.registerTool(name: "get_weather", schema: weatherSchema, handler: weather(location:))
    service.registerTool(
      name: "get_delivery_date",
      description: "Get the delivery date for a customer's order. Call this whenever you need to know the delivery date, for example when a customer asks 'Where is my package'",
      schema: DeliveryLookupData.schema,
      handler: deliveryDate(_:)
    )

    let result = try await service.query(text)
    print("Final result:", result)
  }
}

