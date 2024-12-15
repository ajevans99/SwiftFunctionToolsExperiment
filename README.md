# Swift Function Tools Experiment

This project demonstrates how to integrate [swift-json-schema](https://github.com/ajevans99/swift-json-schema) into a Swift-based conversational assistant. The assistant, powered by the [OpenAI API](https://platform.openai.com/docs/api-reference) using the [MacPaw Swift wrapper](https://github.com/MacPaw/OpenAI), can invoke functions (tools) that expect strictly defined, schema-validated arguments—eliminating guesswork and brittle JSON parsing.

By defining schemas for each tool, you ensure that when the model requests a function call, its arguments match the precise format and types you expect. This leads to more reliable interactions, better error handling, and easier integration with external services (like weather APIs or order tracking systems).

**Defining a Schema:**
```swift
let weatherSchema = JSONObject {
  JSONProperty(key: "location") {
    JSONString()
      .description("The city")
  }
  .required()
}
```

**Registering a Tool:**
```swift
service.registerTool(name: "get_weather", schema: weatherSchema, handler: weather(location:))
```

Here, `get_weather` expects a `location` string. When the model calls it, the arguments are automatically validated. The handler receives a strongly typed Swift `String`—no manual JSON parsing needed.

**Another Tool With a Struct Schema:**
```swift
@Schemable
struct DeliveryLookupData {
  @SchemaOptions(description: "The customer's order ID.")
  let orderID: String
}

service.registerTool(
  name: "get_delivery_date",
  description: "Get the delivery date for a customer's order.",
  schema: DeliveryLookupData.schema,
  handler: deliveryDate(_:)
)
```

In this example, the schema is derived from a Swift struct decorated with `@Schemable`. When the model calls `get_delivery_date`, the `orderID` is extracted and validated automatically.

See the [full code here](Sources/SwiftFunctionToolsExperiment.swift).

## Run locally

To run the Swift executable locally, follow these steps:

1. Checkout the repository

2. In the root directory of the project, create a file named `.env` and add your OpenAI API key:

`OPENAI_KEY="<your-api-key>"`

3. Run the Swift executable

`swift run SwiftFunctionToolsExperiment "How much does shipping cost for express, 6.2 kg, and priority?"`

