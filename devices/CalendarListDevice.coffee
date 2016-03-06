$(document).on( "templateinit", (event) ->

  # define the item class
  class CalendarListDeviceItem extends pimatic.DeviceItem

    constructor: (templData, @device) ->
      super(templData, @device)

      @attrValue = @getAttribute('events').value
      console.log(@attrValue())
      #echo @attrValue

      
    afterRender: (elements) -> 
      super(elements)

      @list = $(elements).find('event-list')



  # register the item-class
  pimatic.templateClasses['CalendarListDeviceTemplate'] = CalendarListDeviceItem
)