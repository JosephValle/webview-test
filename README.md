
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
    - As of now, the WebView requires either an internet connection, or we can store one singular HTML file offline. This would mean no assets, and all script tags in the file.