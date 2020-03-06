function confirmDelete(){
    // var r = confirm("Are you sure?");
    button = document.getElementById('submit_button')
    if (confirm("Are you sure you want to delete this?")){
        button.form.submit();
    }
}
function confirmPlace(){
    // var r = confirm("Are you sure?");
    button = document.getElementById('submit_button')
    if (confirm("Are you sure you want to place this?")){
        button.form.submit();
    }
}

// Material Select Initialization
// $(document).ready(function() {
// $('.mdb-select').materialSelect();
// });

$('#calendar').fullCalendar({
    header: {
        left: 'prev,next today',
        center: 'title',
        right: 'month,agendaWeek,agendaDay,listWeek'
    },
    defaultDate: Date.now().toString(),
    navLinks: true,
    eventLimit: true,
    // events: [{
    //         title: 'Front-End Conference',
    //         start: '2018-11-16',
    //         end: '2018-11-18'
    //     },
    //     {
    //         title: 'Hair stylist with Mike',
    //         start: '2018-11-20',
    //         allDay: true
    //     },
    //     {
    //         title: 'Car mechanic',
    //         start: '2018-11-14T09:00:00',
    //         end: '2018-11-14T11:00:00'
    //     },
    //     {
    //         title: 'Dinner with Mike',
    //         start: '2018-11-21T19:00:00',
    //         end: '2018-11-21T22:00:00'
    //     },
    //     {
    //         title: 'Chillout',
    //         start: '2018-11-15',
    //         allDay: true
    //     },
    //     {
    //         title: 'Vacation',
    //         start: '2018-11-23',
    //         end: '2018-11-29'
    //     },
    // ]
});
function autoUpdateEndTimeMin(){
    console.log('running')
    let startTime = document.getElementById('start-time');
    let endTime = document.getElementById('end-time');
    endTime.min = startTime.value
    endTime.value = startTime.value
};