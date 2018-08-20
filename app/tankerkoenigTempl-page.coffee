$(document).on( "templateinit", (event) ->
# define the item class
	class tankerkoenigDeviceItem extends pimatic.DeviceItem
		constructor: (templData, @device) ->
			@id = @device.id
			super(templData,@device)

		afterRender: (elements) ->
			super(elements)

			renderPrices = (newval) =>
				$("#"+@id+"_tankerkoenig_placeholder").html(newval)

			renderPrices(@getAttribute('prices').value())

			@getAttribute('prices').value.subscribe(renderPrices)

			return
			
	# register the item-class
	pimatic.templateClasses['tankerkoenig'] = tankerkoenigDeviceItem
)