$('#theme').on("click", () => {
    $('.container').toggleClass('lightTheme')
    $('.container').toggleClass('darkTheme')
    $.ajax({
        url: "/switchTheme",
        type: "POST",
        data: {
            'theme': $('.container').hasClass('lightTheme') ? 'lightTheme' : 'darkTheme',
        },
        success: (data) => {}
    })
})