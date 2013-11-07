// Filename: main.js

// Require.js allows us to configure shortcut alias
// There usage will become more apparent further along in the tutorial.
require.config({
	paths: {
    	underscore: '/assets/libs/underscore-min', 
    	backbone: 'libs/backbone-min',
    	util: '/assets/libs/util',
      // jqueryui: '/assets/libs/jqueryui/js/jquery-ui-1.10.2.custom.min',
      mobile : '/assets/libs/jquery.mobile-1.3.1.min',
      // punch : '/assets/libs/jquery.ui.touch-punch.min'
  	},
	shim: {
		underscore:{
			exports : '_'
		},
		backbone: {
			deps : ["underscore", "jquery"],
			exports : "Backbone"
		},
    mobile: {
      deps : ["jquery"],
      exports : "mobile"
    }
    // jqueryui: {
    //   deps : ["jquery", "mobile"],
    //   exports : "jqueryui"
    // }
	}
});

require([
  // Load our app module and pass it to our definition function
  'app',
  'util',
  socket = io.connect()
], function(App){
  App.initialize();
});

