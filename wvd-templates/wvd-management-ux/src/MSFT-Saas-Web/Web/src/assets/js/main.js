$(document).ready(function () {
  $(".dropdown").hover(
    function () {
      $('.dropdown-menu', this).not('.in .dropdown-menu').stop(true, true).slideDown("400");
      $(this).toggleClass('open');
    },
    function () {
      $('.dropdown-menu', this).not('.in .dropdown-menu').stop(true, true).slideUp("400");
      $(this).toggleClass('open');
    }
  );
  $(".navbar-nav a").click(
    function () {
      $(this).parent().toggleClass('open');
    }
  );

});
