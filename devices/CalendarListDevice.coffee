$(document).on( "templateinit", (event) ->

	# define the item class
	class CalendarListDeviceItem extends pimatic.DeviceItem

		constructor: (data) ->
			super(data)

			@attrValue = @getAttribute('events')
			#echo @attrValue

			
		afterRender: (elements) -> 
			super(elements)

			@list = $(elements).find('event-list')



	# register the item-class
	pimatic.templateClasses['CalendarListDeviceTemplate'] = CalendarListDeviceItem
)