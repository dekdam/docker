export default {
  /**
   * @param {Request} request
   * @returns {Promise<Response>}
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (!url.searchParams.has('branch')) {
        return new Response("Branch parameter is required", { status: 400 });
    }
    const branch = url.searchParams.get("branch");
    
    let receivedData;
    try {
      receivedData = await request.json();
    } catch (error) {
      return new Response("Invalid JSON body provided", { status: 400 }); // 400 Bad Request
    }
    const project_id = receivedData.project_id || "";
    if (project_id.toString().trim().length <= 0) {
        return new Response("Project is required", { status: 400 });
    }

    // 1. Prepare data to send
    const dataToSend = {};

    // 2. Set target URL (httpbin.org/post will echo what we send back)
    const targetUrl = `https://gitlab.com/api/v4/projects/${project_id}/pipeline?ref=${branch}`;

    // 3. Create POST request
    const postRequest = new Request(targetUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json", // We send JSON
        "Accept": "application/json",       // We want JSON back
        "PRIVATE-TOKEN": request.headers.get("X-Gitlab-Token") ?? ""      // Custom header we added
      },
      body: JSON.stringify(dataToSend) // Must convert object to string
    });

    try {
      // 4. Execute the request
      const response = await fetch(postRequest);

      // 5. Check if successful
      if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}`);
      }

      // 6. Read the response from the target API (as JSON)
      const responseData = await response.json();

      // 7. Send the result back to the user who called our Worker
      // (We use 200 OK and send back formatted JSON)
      return new Response(JSON.stringify(responseData, null, 2), {
        status: 200,
        headers: {
          "Content-Type": "application/json"
        }
      });

    } catch (error) {
      // In case fetch fails (e.g. network error)
      return new Response(error.message, { status: 500 });
    }
  }
};
