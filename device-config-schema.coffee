# tankerkoenig device configuration options
module.exports = {
  title: "tankerkoenig"
  TankerkoenigDevice :{
    title: "Plugin Properties"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      apiKey:
        description: "Your apiKey"
        type: "string"
        default: ""
      ids:
        description: "The gas station id(s) separated by semicolon"
        type: "string"
        default: ""
      interval:
        description: "How often should the price be updated? (in minutes - minimum 5)"
        type: "number"
        default: 10
      type:
        description: "Which type do you want to see [e5|e10|diesel|all]"
        type: "string"
        default: "all"
      attributes:
        description: "Attributes which shall be exposed by the device"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              enum: [
                "e5Min", "e10Min", "dieselMin", "e5Location", "e10Location", "dieselLocation"
              ]
              description: "price attributes"
            label:
              type: "string"
              description: "The attribute label text to be displayed. The name will be displayed if not set"
              required: false
  }
}
