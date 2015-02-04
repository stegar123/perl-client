// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require bootstrap-sprockets
//= require bootstrap
//= require jquery_ujs
//= require turbolinks
//= require_tree .

$(function(){
  $("td").mousemove(function(e){
    console.log("move")
    var jthis = $(this);
    var info = jthis.find('.details') ;
    if(info.length == 0){
        var data = $('<p>'+jthis.html()+'</p>');
       info =  $("<div class='details'></div>");
       jthis.append(info);
        info.append(data);
    }
    info.css('position', 'fixed');
    info.css('left', e.clientX+15);
    info.css('top', e.clientY+15);
    info.show();
  });
  $("td").hover(function(){
    var jthis = $(this);
    var info = jthis.find('.details');
    info.hide();
  })
});

/*
li.hover(function(e){
}, function(e){
  info.hide();
})
li.mousemove(function(e){
  info.css('position', 'fixed');
  info.css('left', e.clientX+15);
  info.css('top', e.clientY+15);
  info.show();
})
*/
