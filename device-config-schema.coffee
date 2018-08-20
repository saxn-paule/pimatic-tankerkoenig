# tankerkoenig device configuration options
module.exports = {
	title: "tankerkoenig"
	TankerkoenigDevice :{
		title: "Plugin Properties"
		type: "object"
		extensions: ["xLink"]
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
	}
}
