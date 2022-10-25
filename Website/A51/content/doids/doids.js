
// Boid Flocking example.
// Mine I call Doids. Cause, I draw "donuts"
// Original Code : Daniel Shiffman
//                 http://natureofcode.com
// Modified Code : Tobey Peters : tobeypeters@hotmail.com

// In this case, having some globals aren't bad
var flock;

var df = null; // Directional force

var neighbordist = 50;

//START : THIS CODE ISN'T PART OF THE DOIDS PROJECT
var cnv;       //Our Canvas
var wsub = 40; //windowWidth minus this
var hsub = 40; //windowHeight minus this

function positionCanvas () {
  var x = (windowWidth - width) / 2;
  var y = (windowHeight - height) / 2;
  cnv.position(x, y);
}

window.onresize = function() {
  resizeCanvas(windowWidth - wsub, windowHeight - hsub);
  positionCanvas();
}
//END

function setup() {
  //START : THIS CODE ISN'T PART OF THE DOIDS PROJECT
  cnv = createCanvas(windowWidth - wsub, windowHeight - hsub);
  positionCanvas();
  //END

  //console.log('w: ' + width + ' h: ' + height);

  //createCanvas(windowWidth - wsub, windowHeight - hsub);

  flock = new Flock();

  // Add an initial set of Doids into the system
  for (var i = 0; i < 100; i++) {
    flock.doids.push(new doid(width / 2, height / 2));
  }

  // Should never really blindly access elements in an array.
  // But, this isn't a production script
  (flock.doids[0].rc = color(255, 0, 0, random(100, 255)));
  (flock.doids[1].rc = color(0, 255, 0, random(100, 255)));
}

function draw() {
  background(21);

  mouseIsPressed ? (df = createVector(map(mouseX, 0, width, -0.2, 0.2), 0), 
                         drawArrow(df, createVector(width / 2, 50), 500)) : df = createVector(0, 0);

  flock.run();
}

// drawArrow : Draws an arrow showing desired directional force
function drawArrow(v, loc, scale){
  push();
    translate(loc.x, loc.y);

    stroke(255);
    rotate(v.heading());

    var len = v.mag() * scale;
  
    line(0, 0, len, 0);
    line(len, 0, len - 4, 2);
    line(len, 0, len - 4, -2);
  pop();
}

// Flock object : Manages the array of Doids
function Flock() {
  // Initialize array
  this.doids = [ ];
}

Flock.prototype.run = function() {
  for (var el of this.doids) {
    el.run(this.doids);  // Passing the entire list of Doids to each Doid individually
  }
}

// doid class : Contains things Separation, Cohesion, Alignment
function doid(x, y) {
  this.acceleration = createVector(0, 0);
  this.velocity = createVector(random(-1, 1), random(-1, 1));
  this.position = createVector(x, y);
  this.maxspeed = 5;
  this.maxforce = 0.04; // Maximum steering force
  this.rc = color(random(0, 60), random(0, 60), random(0, 255), random(100, 255)); // random fill color
}

doid.prototype.run = function(doids) {
  this.flock(doids);
  this.update();
  this.borders();
  this.render(); 
}

// applyForce : Apply a force to each doid
//              You could add mass here if we want A = F / M
doid.prototype.applyForce = function(force) {
  this.acceleration.add(force);
}

// We accumulate a new acceleration each time based on three rules
doid.prototype.flock = function(doids) {
  var sep = this.separate(doids);   // Separation
  var ali = this.align(doids);      // Alignment
  var coh = this.cohesion(doids);   // Cohesion

  sep.mult(1.5);
  ali.mult(1.0);
  coh.mult(1.0); // Weight the forces
  
  // Add the force vectors to acceleration
  this.applyForce(sep);
  this.applyForce(ali);
  this.applyForce(coh);
  this.applyForce(df);
}

// update : Update the location of a give Doid.
doid.prototype.update = function() {
  this.velocity.add(this.acceleration); // acceleration

  this.velocity.limit(this.maxspeed); // Limit their speed

  this.position.add(this.velocity);

  // Constrain the doid to the visible Canvas 
  this.position.x = constrain(this.position.x, 0, width);
  this.position.y = constrain(this.position.y, 0, height);

  this.acceleration.mult(0); // Reset accelertion to 0 each cycle
}

// seek : Calculates and applies a steering force towards a target
doid.prototype.seek = function(target) {
  var desired = p5.Vector.sub(target, this.position);  // A vector pointing from the location to the target
  var steer = null;

  // Normalize desired and scale to maximum speed
  desired.normalize();
  
  desired.mult(this.maxspeed);

  // Steering = Desired minus Velocity
  return (steer = p5.Vector.sub(desired, this.velocity),
                  steer.limit(this.maxforce), steer); // Limit to maximum steering force
}

// render : Draw the doids on screen
doid.prototype.render = function() {
  push();

    translate(this.position.x, this.position.y);

    fill(this.rc);

    stroke(200);
  
    // TIme to make the donuts, like Fred the Baker
    ellipse(0, 0, 4, 4);
    ellipse(0, 0, 10, 10);
  pop();
}
 
// borders : Change the velecity, if necessary, to make them bounce off walls
doid.prototype.borders = function() {
  if ((this.position.x === 0) || (this.position.x === width) ||
      (this.position.y === 0) || (this.position.y === height)) { this.velocity = createVector(random(-1, 1), random(-1, 1)); 
  } 
}

// separate : Checks for nearby doids and steers away
doid.prototype.separate = function(doids) {
  var desiredseparation = 10.0;
  var steer = createVector(0, 0);
  var count = 0;
  var diff = null;

  // For every doid in the system, check if it's too close
  for (var el of doids) {
    var d = p5.Vector.dist(this.position, el.position);

    (d > 1) && (d < desiredseparation) && 
    (diff = p5.Vector.sub(this.position, el.position), 
    diff.normalize(), diff.div(d), steer.add(diff), count++);
  }

  (count > 0) && steer.div(count);

  // Implement Reynolds: Steering = Desired - Velocity
  return (steer.mag() > 0) ? ( steer.normalize(), steer.mult(this.maxspeed),
                               steer.sub(this.velocity), steer.limit(this.maxforce),
                               steer) : steer;
}

// align : For every nearby Doid in the system, calculate the average velocity
doid.prototype.align = function(doids) {
  var sum = createVector(0, 0);
  var count = 0;
  var steer = null;

  for (var el of doids) {
    var d = p5.Vector.dist(this.position, el.position);

    (d > 0) && (d < neighbordist) && (sum.add(el.velocity), count++);
  }

  return (count > 0) ? (sum.div(count), sum.normalize(), 
                        sum.mult(this.maxspeed), steer = p5.Vector.sub(sum,this.velocity),
                        steer.limit(this.maxforce), steer) : createVector(0, 0);
}

// cohesion : For the average location (i.e. center) of all nearby Doids, 
//            calculate steering vector towards that location
doid.prototype.cohesion = function(doids) {
  var sum = createVector(0, 0); // Accumulate all doid locations
  var count = 0;

  for (var el of doids) {
    var d = p5.Vector.dist(this.position, el.position);

    (d > 0) && (d < neighbordist) && (sum.add(el.position), count++);
  }

  return (count > 0) ? (sum.div(count), this.seek(sum)) : createVector(0, 0);
}