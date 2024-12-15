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

@Schemable
enum DeliveryType {
  case standard
  case express
  case overnight
}

@Schemable
struct ShippingEstimateRequest {
  @SchemaOptions(description: "The weight of the package in kilograms")
  let weight: Double

  @SchemaOptions(description: "Whether this should be a priority delivery")
  let priority: Bool

  @SchemaOptions(description: "The type of delivery requested.")
  var deliveryType: DeliveryType = .standard

  @SchemaOptions(description: "A list of extra features requested by the customer")
  @ArrayOptions(minContains: 1)
  let extras: [String]?
}

func calculateShippingCost(_ request: ShippingEstimateRequest) async -> String {
  print("Hello from calculateShippingCost")
  print("Mocking call for \(request)")
  return "Shipping cost: $20"
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
    service.registerTool(
      name: "calculate_shipping_cost",
      description: "Estimate shipping cost for a customer's order.",
      schema: ShippingEstimateRequest.schema,
      handler: calculateShippingCost
    )

    let result = try await service.query(text)
    print("Final result:", result)
  }
}

