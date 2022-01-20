function myFunction() {
	let d = new Date();
	document.getElementById("demo").innerHTML = "<h1>Today's date is " + d + "</h1>"
} 

function fromFlutter(newTitle) {
    document.getElementById("title").innerHTML = newTitle;
    // sendBack();
}

function sendToFlutter(message) {
    messageHandler.postMessage(message);
}