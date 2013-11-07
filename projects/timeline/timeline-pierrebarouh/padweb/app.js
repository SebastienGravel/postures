var express = require("express")
, app = express()
, http = require('http')
, server = http.createServer(app).listen(8085)
, io = require('socket.io').listen(server, { log: false })
, sys = require('sys')
, readline = require('readline')
, freeport = require("freeport")
, osc = require('node-osc');

io.set('browser client gzip', true);
io.set('browser client minification', true);  // send minified client
io.set('browser client etag', true);          // apply etag caching logic based on version number

//*** PARAM EXPRESS ***//
app.use("/assets", express.static(__dirname + "/assets"));
app.use("/js", express.static(__dirname + "/js"));
app.get('/', function (req, res){ res.sendfile(__dirname + '/index.html'); });
app.get('/test', function (req, res){ res.sendfile(__dirname + '/test.html'); });



///*** PARAMS ***///
var address = "localhost"
,	port = 16042
,	oscAddress = "/posture/cmd"
,   brushAddress = "/posture/brush"
,   surfaceAddress = "/posture/surface"
,   calibrationAddress = "/posture/calibrate"
,   oscSpin = "/SPIN/drawingspace/apollo"
,   orientationDelta = 0
,   enableOrientation = false;

function puts(error, stdout, stderr) {
    sys.puts(stdout)
}

var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

process.argv.forEach(function (val, index, array) {
    if (val == "-ip")
        address = process.argv[index+1];
    if (val == "-p")
        port = process.argv[index+1];
    if (val == "-o") {
        oscAddress = oscAddress + "_" + process.argv[index+1];
        brushAddress = brushAddress + "_" + process.argv[index+1];
        surfaceAddress = surfaceAddress + "_" + process.argv[index+1];
        calibrationAddress = calibrationAddress + "_" + process.argv[index+1];

    }
    if (val == "-s")
        oscSpin = process.argv[index+1];
    if (val == "-alpha")
        orientationDelta = process.argv[index+1];
    if (val == "-orientation")
        enableOrientation = true;
});

///*** OSC clients ***///
var client = new osc.Client("localhost", port);
console.log("Address OSC : "+address+oscAddress, "port : "+port);
client.send(oscAddress, "test send message"); //test send

var spinClient = new osc.Client(address, 54324);


///*** SOCKET.IO ***///
io.sockets.on('connection', function (socket) {
    var speed = 0.0;

    socket.on("getOrientationDelta", function(state) {
        socket.emit("orientationDelta", orientationDelta);
    });

    socket.on("pressBtn", function(state) {
        client.send(oscAddress, state);
	})

    socket.on("pressBrush", function(state) {
        client.send(brushAddress, state);
    })

    socket.on("switchProjection", function(state) {
        client.send(surfaceAddress, state);
    })
    socket.on("calibrate", function(stateMirror, value) {
        client.send(calibrationAddress, stateMirror, Number(value));
    })
    socket.on("speed", function(state) {
        speed = state;
    })

    socket.on("orientation", function(state) {
        if (enableOrientation)
            spinClient.send(oscSpin, "setOrientation", state.pitch, 0.00000001, state.yaw);
    })

    socket.on("velocity", function(state) {
        spinClient.send(oscSpin, "setVelocity", state.x * speed, state.y * speed, state.z * speed);
    })
});
