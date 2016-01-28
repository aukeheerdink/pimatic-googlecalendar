$(document).on( "templateinit", (event) ->

  # define the item class
  class CalendarListDeviceItem extends pimatic.DeviceItem

    constructor: (data) ->
      super(data)

    afterRender: (elements) -> 
      super(elements)


  # register the item-class
  pimatic.templateClasses['CalendarListDeviceTemplate'] = CalendarListDeviceItem
)