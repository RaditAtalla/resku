// web/llama_worker.js
importScripts("https://cdn.jsdelivr.net/npm/@mlc-ai/web-llm@0.2.46/dist/index.js");

self.onmessage = async function(e) {
  const { action, payload } = e.data;
  
  if (action === 'initialize') {
    try {
      // Load cached GGUF model
      self.engine = new webllm.MLCEngine();
      await self.engine.reload(payload.modelId);
      self.postMessage({ status: 'ready' });
    } catch (err) {
      self.postMessage({ status: 'error', error: err.toString() });
    }
  }
  
  if (action === 'infer') {
    try {
      const chatCompletion = await self.engine.chat.completions.create({
        messages: [
          { role: "system", content: payload.systemPrompt },
          { role: "user", content: payload.userPrompt }
        ],
        stream: true,
        temperature: 0.2
      });
      
      for await (const chunk of chatCompletion) {
        const token = chunk.choices[0].delta.content || "";
        self.postMessage({ status: 'token', token: token });
      }
      self.postMessage({ status: 'complete' });
    } catch (err) {
      self.postMessage({ status: 'error', error: err.toString() });
    }
  }
};
