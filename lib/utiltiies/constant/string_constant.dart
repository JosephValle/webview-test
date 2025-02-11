class StringConstant {
  static const String mainUrl = 'https://super-frangipane-224a80.netlify.app/';
  static const String docs = '''

# How to Create a Custom Active Task for MyCap Data

Creating a custom Application for MyCap allows you to develop your own Active Tasks and send structured JSON data back to the MyCap app via JavaScript via an In-App WebView. This guide will walk you through how to set up your website to properly communicate with the app, ensuring seamless integration into your RedCap Database.

## 1. Understanding How the WebView Receives Data

The MyCap app displays your active task using a WebView, and it listens for JavaScript messages sent via a JavaScript Channel named "returnData". Your website needs to include JavaScript logic to send data using window.returnData.postMessage(...).

Your website must:

    Be publicly accessible on the web.
    Have JavaScript enabled.
    Format responses as JSON strings.

## 2. Setting Up Your Website to Send JSON Data

You can use any backend language (Node.js, Python, PHP, etc.) to generate and serve data. However, the key part is your frontend JavaScript that communicates with the WebView.
Example Web Page (HTML + JavaScript)

This simple page allows users to enter data, which is then sent to the MyCap WebView.

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebView Example</title>
</head>
<body>
    <h2>Enter Text</h2>
    <input type="text" id="userInput" placeholder="Type something...">
    <button onclick="submitData()">Submit</button>
    <p id="errorMessage" class="error" style="display: none;"></p>

    <script>
    function submitData() {
        const inputValue = document.getElementById("userInput").value;
        const result = JSON.stringify({ text: inputValue });
        const errorMessage = document.getElementById("errorMessage");

        try {
            if (window.returnData && typeof window.returnData.postMessage === "function") {
                window.returnData.postMessage(result);
                console.log("Data sent successfully:", result);
            } else {
                throw new Error("JavaScript channel 'returnData' is not available.");
            }

            // Close WebView after sending data
            setTimeout(() => {
                window.close();
            }, 500);
        } catch (error) {
            console.error("Error sending data:", error);
            errorMessage.textContent = error.message;
            errorMessage.style.display = "block"; // Show error message on the screen
        }
    }
    </script>

</body>
</html>
```
How This Works

- The user enters data into the text box.
- Clicking the Submit button converts it into a JSON object:

```{ "text": "User input here" }```

The JSON is sent to the MyCap app using:

    window.returnData.postMessage(result);

### 2.1. Sending files: Images, Audio, etc.

We accept files as a base 64 encoded string. Here's an example of how to send an image:

```
function captureImage() {
      const video = document.getElementById("video");
      const canvas = document.getElementById("canvas");
      // Set canvas dimensions equal to video dimensions
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const context = canvas.getContext('2d');
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      // Convert the canvas image to a data URL (base64)
      canvas.toBlob(function(blob) {
        const reader = new FileReader();
        reader.onloadend = function() {
          result.image = reader.result; // This is a base64 string representing the image bytes.
          // Stop the video stream
          if (videoStream) {
            videoStream.getTracks().forEach(track => track.stop());
          }
          // Proceed to next page
          nextPage();
        }
        reader.readAsDataURL(blob);
      }, 'image/png');
    }
```

## 3. How to Host Your Website

As of now, your webpage must be hosted online for the Flutter WebView to access it. Here are a few hosting options:

Hosting Service	Notes
- Netlify: Free tier available, simple to use
- Vercel: Great for JavaScript-based sites
- GitHub Pages: Works well for static sites
- Firebase Hosting: Google-backed hosting
- Custom Server: Use Nginx/Apache to serve

Once hosted, your page will have a URL like:

https://your-site.com/webview-page.html

This URL can be added on the project on RedCap, along with any custom parameters you may need.

## 4. Summary

✅ Your website must:

- Host a web page with JavaScript that sends JSON data to window.returnData.postMessage(...).
- Be publicly accessible
- Optionally, have a backend API to generate data dynamically.

With this setup, MyCap can receive structured data from any website hosted on the web, regardless of the backend technology used.

🚀 Now you can integrate any custom Active Task For MyCap!

## FAQ
- Can I utilize device mechanisms such as sensors or health data?
    - No, due to security limitations, you can only use services allowed within websites, such as location or camera.
- Can the tasks be completed while offline?
    - As of now, the WebView requires either an internet connection, or we can store one singular HTML file offline. This would mean no assets, and all script tags in the file.''';

  static const String html = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Tapping Test</title>
  <!-- Using Bootstrap 4 for basic styling -->
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" />
  <style>
    /* Custom styles */
    .page { display: none; }
    .active { display: block; }
    .top-bar {
      padding: 10px;
      background-color: #f8f9fa;
      border-bottom: 1px solid #dee2e6;
    }
    .bottom-bar {
      padding: 10px;
      background-color: #f8f9fa;
      border-top: 1px solid #dee2e6;
      text-align: center;
    }
    .tap-button {
      width: 100px;
      height: 100px;
      border-radius: 50%;
      font-size: 18px;
      color: white;
      background-color: blue;
      border: none;
    }
    .content { margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container" id="app"></div>

  <script>
    /**************** Global Variables & Configuration ****************/
    let currentPageIndex = 0;
    let pages = [];
    let totalPages = 0;
    // Read configuration from URL parameters (with defaults)
    const urlParams = new URLSearchParams(window.location.search);
    const config = {
      identifier: urlParams.get('identifier') || 'defaultIdentifier',
      // Test duration in seconds (default 30)
      lengthOfTest: parseInt(urlParams.get('length_of_test')) || 30,
      // handOptions: '.Both', '.Right', or '.Left' (default is '.Both')
      handOptions: urlParams.get('handOptions') || '.Both',
      // Optional description string; fallback text if not provided
      intendedUseDescription: urlParams.get('intendedUseDescription') || 'Welcome to the Tapping Test. Please follow the instructions below.'
    };

    // Global result object – the final JSON to be sent.
    // It now includes fields for image, audio, and location.
    let result = {
      rightHand: {},
      leftHand: {},
      image: null,       // to hold image bytes (as base64 string)
      audio: null,       // to hold audio recording bytes (as base64 string)
      location: { latitude: null, longitude: null }  // nullable lat/long
    };

    // Test state variables (used on each test page)
    let testRunning = false;
    let testStartTime = 0;
    let tapCount = 0;
    let samples = [];       // Array to store tap samples
    let accEvents = [];     // Array to store accelerometer (device motion) events
    let testInterval = null;
    let currentTestHand = ""; // "RIGHT" or "LEFT"

    // Variables for extra media capture
    let videoStream = null;
    let mediaRecorder = null;
    let audioChunks = [];

    /**************** Page Setup ****************/
    // Build the pages array based on the handOptions.
    // For ".Both": common intro, right hand intro, right test, left hand intro, left test,
    // then extra steps: image capture, audio recording, location capture, then completion.
    // For ".Right" or ".Left": common intro, hand-specific intro, test, then extra steps, then completion.
    function initPages() {
      pages = [];
      // Page 0: Common intro (displaying received URL parameters)
      pages.push({
        type: 'intro',
        title: 'Tapping Test',
        instructions: [
          config.intendedUseDescription,
          'This test will measure your tapping speed.'
        ]
      });
      if (config.handOptions === '.Both' || config.handOptions === '.Right') {
        // For right hand test
        pages.push({
          type: 'intro',
          hand: 'RIGHT',
          title: 'Right Hand Test',
          instructions: [`Tap the buttons using your RIGHT hand for ${config.lengthOfTest} seconds.`]
        });
        pages.push({
          type: 'test',
          hand: 'RIGHT'
        });
      }
      if (config.handOptions === '.Both' || config.handOptions === '.Left') {
        // For left hand test
        pages.push({
          type: 'intro',
          hand: 'LEFT',
          title: 'Left Hand Test',
          instructions: [`Tap the buttons using your LEFT hand for ${config.lengthOfTest} seconds.`]
        });
        pages.push({
          type: 'test',
          hand: 'LEFT'
        });
      }
      // Extra Step: Capture an Image
      pages.push({
        type: 'captureImage',
        title: 'Capture Image',
        instructions: ['Capture an image using your camera.']
      });
      // Extra Step: Record Audio
      pages.push({
        type: 'recordAudio',
        title: 'Record Audio',
        instructions: ['Record an audio clip using your microphone.']
      });
      // Extra Step: Capture Location
      pages.push({
        type: 'captureLocation',
        title: 'Capture Location',
        instructions: ['Allow location access to capture your latitude and longitude (optional).']
      });
      // Final page: Completion
      pages.push({
        type: 'completion',
        title: 'Completion',
        instructions: ['Test complete. Thank you!']
      });
      totalPages = pages.length;
    }

    /**************** Rendering & Navigation ****************/
    // Render the current page into the #app container
    function renderPage(index) {
      const page = pages[index];
      let html = '';

      // Top Bar with page count and (if applicable) a Back button.
      html += `<div class="top-bar d-flex justify-content-between align-items-center">
                 <div>Page ${index + 1} of ${totalPages}</div>`;
      // Only show Back button on non-test pages (and not on first page)
      if (index > 0 && page.type !== 'test' && page.type !== 'completion') {
        html += `<button id="backButton" class="btn btn-secondary">Back</button>`;
      }
      html += `</div>`;

      // Main Content based on page type
      html += `<div class="content">`;
      if (page.type === 'intro') {
        html += `<h2>${page.title}</h2>`;
        page.instructions.forEach(instr => {
          html += `<p>${instr}</p>`;
        });
        // On the first page, display the received URL parameters.
        if (index === 0) {
          html += `<div class="card mb-3">
                     <div class="card-body">
                       <h5 class="card-title">Received Parameters</h5>
                       <pre id="jsonDisplay">${JSON.stringify(config, null, 2)}</pre>
                     </div>
                   </div>`;
        }
        // Optional: A placeholder image (replace with your own if desired)
        html += `<img src="left_hand_tap.png" alt="Instruction Image" class="img-fluid my-3"/>`;
      } else if (page.type === 'test') {
        html += `<h2>Tapping Speed</h2>`;
        html += `<p>Tap the buttons using your ${page.hand} hand.</p>`;
        html += `<div id="progressContainer" class="progress mb-3">
                   <div id="progressBar" class="progress-bar" role="progressbar" style="width: 0%;"></div>
                 </div>`;
        html += `<div>
                   <p>Total Taps: <span id="tapCount">0</span></p>
                 </div>`;
        html += `<div class="d-flex justify-content-center">
                   <button id="leftButton" class="tap-button mx-3">Tap</button>
                   <button id="rightButton" class="tap-button mx-3">Tap</button>
                 </div>`;
      } else if (page.type === 'captureImage') {
        html += `<h2>${page.title}</h2>`;
        page.instructions.forEach(instr => {
          html += `<p>${instr}</p>`;
        });
        html += `<video id="video" autoplay playsinline style="width: 100%; max-width: 400px;"></video>`;
        html += `<canvas id="canvas" style="display:none;"></canvas>`;
        html += `<div class="bottom-bar"><button id="captureButton" class="btn btn-primary">Capture Image</button></div>`;
      } else if (page.type === 'recordAudio') {
        html += `<h2>${page.title}</h2>`;
        page.instructions.forEach(instr => {
          html += `<p>${instr}</p>`;
        });
        html += `<div id="audioControls" class="mb-3">
                   <button id="startRecording" class="btn btn-primary">Start Recording</button>
                   <button id="stopRecording" class="btn btn-secondary" disabled>Stop Recording</button>
                 </div>`;
      } else if (page.type === 'captureLocation') {
        html += `<h2>${page.title}</h2>`;
        page.instructions.forEach(instr => {
          html += `<p>${instr}</p>`;
        });
        html += `<p id="locationStatus">Attempting to get location...</p>`;
        html += `<div class="bottom-bar"><button id="locationNextButton" class="btn btn-primary">Next</button></div>`;
      } else if (page.type === 'completion') {
        html += `<h2>${page.title}</h2>`;
        page.instructions.forEach(instr => {
          html += `<p>${instr}</p>`;
        });
        html += `<p>Submitting results...</p>`;
      }
      html += `</div>`;

      // Bottom Bar (only on non-test pages except some extra steps which have their own controls)
      if ((page.type === 'intro' || page.type === 'completion') && page.type !== 'test' && page.type !== 'captureImage' && page.type !== 'recordAudio' && page.type !== 'captureLocation') {
        html += `<div class="bottom-bar">`;
        // Show Next button if not on the final (completion) page
        if (index < totalPages - 1 && page.type !== 'completion') {
          html += `<button id="nextButton" class="btn btn-primary">Next</button>`;
        }
        // On the completion page, offer a Submit button.
        if (page.type === 'completion') {
          html += `<button id="submitButton" class="btn btn-success">Submit</button>`;
        }
        html += `</div>`;
      }

      document.getElementById("app").innerHTML = html;

      // Attach navigation button listeners
      const backBtn = document.getElementById("backButton");
      if (backBtn) backBtn.addEventListener("click", prevPage);
      const nextBtn = document.getElementById("nextButton");
      if (nextBtn) nextBtn.addEventListener("click", nextPage);
      const submitBtn = document.getElementById("submitButton");
      if (submitBtn) submitBtn.addEventListener("click", submitResults);

      // If this is a test page, initialize test state and attach tap listeners.
      if (page.type === 'test') {
        // Reset test state
        testRunning = false;
        testStartTime = 0;
        tapCount = 0;
        samples = [];
        accEvents = [];
        currentTestHand = page.hand;
        document.getElementById("tapCount").textContent = "0";

        // Set up tap button listeners
        document.getElementById("leftButton").addEventListener("click", function(e) {
          handleTap(e, "Left");
        });
        document.getElementById("rightButton").addEventListener("click", function(e) {
          handleTap(e, "Right");
        });
      }

      // Extra Step: Capture Image
      if (page.type === 'captureImage') {
        // Request camera access and stream video to the video element.
        const video = document.getElementById("video");
        navigator.mediaDevices.getUserMedia({ video: true })
          .then(stream => {
            videoStream = stream;
            video.srcObject = stream;
          })
          .catch(err => {
            console.error("Error accessing camera: ", err);
            video.parentElement.innerHTML = "<p>Camera access denied or not available.</p>";
          });

        // Attach listener for capture button
        document.getElementById("captureButton").addEventListener("click", captureImage);
      }

      // Extra Step: Record Audio
      if (page.type === 'recordAudio') {
        const startBtn = document.getElementById("startRecording");
        const stopBtn = document.getElementById("stopRecording");

        startBtn.addEventListener("click", startAudioRecording);
        stopBtn.addEventListener("click", stopAudioRecording);
      }

      // Extra Step: Capture Location
      if (page.type === 'captureLocation') {
        // Attempt to get location
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              result.location.latitude = position.coords.latitude;
              result.location.longitude = position.coords.longitude;
              document.getElementById("locationStatus").textContent =
                `Latitude: ${position.coords.latitude}, Longitude: ${position.coords.longitude}`;
            },
            (error) => {
              console.error("Error obtaining location:", error);
              result.location.latitude = null;
              result.location.longitude = null;
              document.getElementById("locationStatus").textContent = "Location not available.";
            }
          );
        } else {
          result.location.latitude = null;
          result.location.longitude = null;
          document.getElementById("locationStatus").textContent = "Geolocation not supported.";
        }
        // Attach listener to next button on location page.
        document.getElementById("locationNextButton").addEventListener("click", nextPage);
      }
    }

    function nextPage() {
      if (currentPageIndex < totalPages - 1) {
        currentPageIndex++;
        renderPage(currentPageIndex);
      } else {
        // If on the last page, submit the results.
        submitResults();
      }
    }

    function prevPage() {
      if (currentPageIndex > 0) {
        currentPageIndex--;
        renderPage(currentPageIndex);
      }
    }

    /**************** Test (Tapping) Logic ****************/
    // Handle a tap event on one of the test buttons.
    function handleTap(e, buttonSide) {
      // Get tap coordinates (clientX, clientY)
      const x = e.clientX;
      const y = e.clientY;
      const btnId = (buttonSide === "Left") ? ".Left" : ".Right";
      // If the test has not yet started, start it.
      if (!testRunning) {
        startTest();
      }
      tapCount++;
      document.getElementById("tapCount").textContent = tapCount;
      const timestamp = Date.now() - testStartTime;
      samples.push({
        locationX: x,
        locationY: y,
        buttonIdentifier: btnId,
        timestamp: timestamp
      });
    }

    // Start the test: record the start time, begin updating the progress bar,
    // and add a device motion listener (if available).
    function startTest() {
      testRunning = true;
      testStartTime = Date.now();
      testInterval = setInterval(function() {
        const elapsed = Date.now() - testStartTime;
        const progressPercent = Math.min((elapsed / (config.lengthOfTest * 1000)) * 100, 100);
        document.getElementById("progressBar").style.width = progressPercent + "%";
        if (elapsed >= config.lengthOfTest * 1000) {
          stopTest();
        }
      }, 50);
      // Listen for device motion events (if supported).
      window.addEventListener("devicemotion", deviceMotionHandler);
    }

    // Stop the test: stop the timer, remove the motion listener, gather button data,
    // record the test results, and then automatically navigate to the next page.
    function stopTest() {
      clearInterval(testInterval);
      testRunning = false;
      window.removeEventListener("devicemotion", deviceMotionHandler);

      // Gather button data (using getBoundingClientRect)
      const leftBtn = document.getElementById("leftButton");
      const rightBtn = document.getElementById("rightButton");
      const leftRect = leftBtn.getBoundingClientRect();
      const rightRect = rightBtn.getBoundingClientRect();
      const btnInfo = {
        buttonRect1: {
          locationX: leftRect.left,
          locationY: leftRect.top,
          width: leftRect.width,
          height: leftRect.height
        },
        buttonRect2: {
          locationX: rightRect.left,
          locationY: rightRect.top,
          width: rightRect.width,
          height: rightRect.height
        },
        stepViewSize: {
          width: window.innerWidth,
          height: window.innerHeight
        },
        samples: samples
      };

      // Save the results for the current test hand.
      if (currentTestHand === "RIGHT") {
        result.rightHandAccData = accEvents;
        result.rightHand = btnInfo;
      } else if (currentTestHand === "LEFT") {
        result.leftHandAccData = accEvents;
        result.leftHand = btnInfo;
      }
      // Automatically go to the next page after a short delay.
      setTimeout(nextPage, 500);
    }

    // Device motion event handler: record acceleration values along with a timestamp.
    function deviceMotionHandler(event) {
      const acceleration = event.acceleration;
      const timestamp = Date.now() - testStartTime;
      if (acceleration) {
        accEvents.push({
          x: acceleration.x,
          y: acceleration.y,
          z: acceleration.z,
          timestamp: timestamp
        });
      }
    }

    /**************** Extra Step: Capture Image ****************/
    function captureImage() {
      const video = document.getElementById("video");
      const canvas = document.getElementById("canvas");
      // Set canvas dimensions equal to video dimensions
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const context = canvas.getContext('2d');
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      // Convert the canvas image to a data URL (base64)
      canvas.toBlob(function(blob) {
        const reader = new FileReader();
        reader.onloadend = function() {
          result.image = reader.result; // This is a base64 string representing the image bytes.
          // Stop the video stream
          if (videoStream) {
            videoStream.getTracks().forEach(track => track.stop());
          }
          // Proceed to next page
          nextPage();
        }
        reader.readAsDataURL(blob);
      }, 'image/png');
    }

    /**************** Extra Step: Record Audio ****************/
    function startAudioRecording() {
      const startBtn = document.getElementById("startRecording");
      const stopBtn = document.getElementById("stopRecording");
      startBtn.disabled = true;
      stopBtn.disabled = false;
      audioChunks = [];

      navigator.mediaDevices.getUserMedia({ audio: true })
        .then(stream => {
          mediaRecorder = new MediaRecorder(stream);
          mediaRecorder.ondataavailable = function(e) {
            if (e.data && e.data.size > 0) {
              audioChunks.push(e.data);
            }
          };
          mediaRecorder.onstop = function() {
            // Convert recorded audio chunks to a blob, then to base64.
            const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            const reader = new FileReader();
            reader.onloadend = function() {
              result.audio = reader.result; // base64 string of audio bytes.
              // Stop all audio tracks.
              stream.getTracks().forEach(track => track.stop());
              // Proceed to next page.
              nextPage();
            }
            reader.readAsDataURL(audioBlob);
          };
          mediaRecorder.start();
        })
        .catch(err => {
          console.error("Error accessing microphone: ", err);
          startBtn.disabled = false;
          stopBtn.disabled = true;
          alert("Microphone access denied or not available.");
        });
    }

    function stopAudioRecording() {
      const stopBtn = document.getElementById("stopRecording");
      stopBtn.disabled = true;
      if (mediaRecorder && mediaRecorder.state !== "inactive") {
        mediaRecorder.stop();
      }
    }

    /**************** Submit Results ****************/
    // When finished, send the results as JSON via the JavaScript channel
    // (if available) and then close the window.
    function submitResults() {
      const jsonResult = JSON.stringify(result);
      if (window.returnData && typeof window.returnData.postMessage === "function") {
        window.returnData.postMessage(jsonResult);
        console.log("Data sent successfully:", jsonResult);
      } else {
        console.log("JSON Result:", jsonResult);
      }
      // Optionally close the window after a short delay.
      setTimeout(function() {
        window.close();
      }, 500);
    }

    /**************** Initialization ****************/
    // Initialize pages and render the first page.
    initPages();
    renderPage(currentPageIndex);
  </script>
</body>
</html>
''';
}
