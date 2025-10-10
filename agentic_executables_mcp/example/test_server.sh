#!/bin/bash
# Test script for Prompts Framework MCP Server
# This script demonstrates how to manually test the MCP server

echo "Testing Prompts Framework MCP Server"
echo "======================================"
echo ""

# Test 1: Get AE Instructions for library bootstrap
echo "Test 1: Get AE Instructions (library, bootstrap)"
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}}}' | dart run bin/agentic_executables_mcp_server.dart
echo ""

# Note: The server uses STDIO and expects JSON-RPC 2.0 protocol
# For proper testing, use an MCP client or a tool like `mcp-cli` if available

echo ""
echo "For full testing, use an MCP-compatible client such as:"
echo "- Claude Desktop with MCP support"
echo "- Custom MCP client using dart_mcp package"
echo "- MCP Inspector tool"
echo ""
echo "Example tool call payload:"
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_ae_instructions","arguments":{"context_type":"library","action":"bootstrap"}}}'
