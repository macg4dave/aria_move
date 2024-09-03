<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<h1>Aria2 Download Completion Script</h1>

<p>This script automates the process of moving downloaded files or directories from a designated incoming folder to a completed folder once the download is finished using <code>aria2c</code>. It also includes robust logging capabilities with configurable log levels for easy debugging and monitoring.</p>

<h2>Features</h2>
<ul>
    <li>Automatically moves completed downloads to a specified directory.</li>
    <li>Handles both individual files and entire directories.</li>
    <li>Ensures unique file names to prevent overwriting existing files.</li>
    <li>Configurable logging levels:
</ul>

<h2>Installation</h2>
<ol>
    <li>Download the script and place it in your desired directory.</li>
    <li>Make the script executable:
        <pre><code>chmod +x aria_move.sh</code></pre>
    </li>
</ol>

<h2>Configuration</h2>
<p>The script uses several variables to define paths and behavior. Adjust these variables at the beginning of the script:</p>
<ul>
    <li><code>DOWNLOAD</code>: Path to the incoming downloads directory (no trailing slash).</li>
    <li><code>COMPLETE</code>: Path to the completed downloads directory (no trailing slash).</li>
    <li><code>LOG_FILE</code>: Path to the log file.</li>
    <li><code>LOG_LEVEL</code>: Set the logging level.</li>
</ul>

<h2>Usage</h2>
<p>The script is designed to be called by <code>aria2c</code> when a download is completed.</p>
<ol>
    <li>Configure your <code>aria2c</code> settings to trigger this script on download completion. Add the following line to your <code>aria2.conf</code>:
        <pre><code>on-download-complete=/path/to/aria_move.sh</code></pre>
    </li>
    or
        <li>Configure your <code>aria2c</code> settings to trigger this script on download completion. Add the following line to your <code>aria2.conf</code>:
        <pre><code>$aria2c --on-download-complete=/path/to/aria_move.sh</code></pre>
    </li>
</ol>
<h2>Logging</h2>
<p>The script logs various events to a specified log file, including:</p>
<ul>
    <li>Completion of download tasks.</li>
    <li>Any errors encountered during file or directory moves.</li>
    <li>Debug information.</li>
</ul>
<p>Log entries include timestamps for easier tracking.</p>

<h2>Examples</h2>
<p>Here’s an example of how you might configure and use the script:</p>
<pre><code>#!/bin/sh

DOWNLOAD="/mnt/World/incoming"
COMPLETE="/mnt/World/completed"
LOG_FILE="/mnt/World/mvcompleted.log"
LOG_LEVEL=4

</code></pre>

<h2>Contributing</h2>
<p>If you'd like to contribute to this project, please fork the repository and submit a pull request. Bug reports and feature requests are also welcome through the issue tracker.</p>

<h2>License</h2>
<p>This project is licensed under the MIT License. See the <code>LICENSE</code> file for details.</p>

</body>
</html>
