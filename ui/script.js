$(function(){
    $(".box").hide()
    $(".confirmationbox").hide()
    window.addEventListener("message", function(event){
        let ev = event.data
        // console.log(ev.yesno)
        // console.log(ev.show)
        if (ev.yesno == null || ev.yesno == false){
            if (ev.show){
                if (ev.isnew) {
                    $(".box").fadeIn("fast")
                    $('#title').text('Dispatch Information ' + ev.time)
                    $('#instructions1').text('Arrows to Navigate - [ to toggle Respond')
                    $('#instructions2').text('H to set Waypoint - ] to Delete')
                }
                $('#incident').text('#' + ev.incident)
                $('#type').text(ev.type)
                $('#details').text(ev.details)
                $('#location').text(ev.location)
                $('#responders').text(ev.responders.join(', '))
            } else {
                $(".box").fadeOut("slow")
            }
        } else {
            if (ev.show) {
                $(".confirmationbox").fadeIn("fast")
            } else {
                $(".confirmationbox").fadeOut("slow")
            }
        }
    })
})