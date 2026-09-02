# Abliterated GGUF model research

## Sources reviewed

- https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Instruct-abliterated-GGUF
- https://huggingface.co/mradermacher/Qwen2-VL-7B-Instruct-abliterated-GGUF

## Findings

The Qwen2.5-Coder 7B Instruct abliterated GGUF page is explicitly tagged `abliterated` and `uncensored`. Its Q4_K_S file is listed at approximately 4.6 GB and marked fast/recommended; Q4_K_M is approximately 4.8 GB. Q5_K_M is approximately 5.5 GB and Q6_K approximately 6.4 GB.

The Qwen2-VL 7B Instruct abliterated GGUF page is explicitly tagged `abliterated` and `uncensored`, and provides image understanding. Its Q4_K_S file is approximately 4.6 GB and marked fast/recommended; Q4_K_M is approximately 4.8 GB. It also requires a separate `mmproj-fp16` multimodal supplement listed at approximately 1.5 GB. Q5 and larger variants use more memory.

The catalog should prioritize Q4_K_S/Q4_K_M models for iPhone 14-class devices, mark 7B models as memory-intensive, and preserve the user’s existing Qwen2.5-Coder 3B as the lightweight recommended default. The vision model should be clearly labeled as requiring multimodal runtime support; the current text-only chat path cannot automatically analyze image pixels merely by downloading the GGUF.

## Additional verified model

The mradermacher Mistral-7B-Instruct-v0.3-abliterated-GGUF page is tagged `abliterated` and `uncensored`. Its Q4_K_S quant is approximately 4.2 GB and Q4_K_M approximately 4.5 GB, both listed as fast/recommended. It is a text-generation model and does not provide native image understanding.

Candidate catalog entries should therefore include the existing Qwen2.5-Coder 3B, Qwen2.5-Coder 7B Q4_K_S, Mistral 7B v0.3 Q4_K_S, and Qwen2-VL 7B Q4_K_S plus its mmproj supplement. Models larger than these should be optional premium imports rather than bundled recommendations because of storage and memory pressure on iPhone-class devices.
