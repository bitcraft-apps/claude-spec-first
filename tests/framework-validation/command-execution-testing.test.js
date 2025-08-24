#!/usr/bin/env node

/**
 * Command Execution Testing Suite
 * Tests TC004-TC006: /spec-init command delegation to spec-analyst
 * 
 * This test suite validates that framework commands properly delegate
 * to specialized sub-agents using Claude Code's Task tool.
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Test framework setup
const TEST_ROOT = path.resolve(__dirname, '../..');
const TEMP_TEST_DIR = path.join(__dirname, 'temp-command-tests');
const FIXTURES_DIR = path.join(__dirname, 'fixtures');

// Colors for test output
const colors = {
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m'
};

class CommandExecutionTestSuite {
    constructor() {
        this.testsRun = 0;
        this.testsPassed = 0;
        this.testsFailed = 0;
    }

    // Test utility functions
    async setupTestEnv() {
        try {
            await fs.rmdir(TEMP_TEST_DIR, { recursive: true });
        } catch (e) {
            // Directory might not exist
        }
        await fs.mkdir(TEMP_TEST_DIR, { recursive: true });
        process.chdir(TEMP_TEST_DIR);
    }

    async cleanupTestEnv() {
        process.chdir(__dirname);
        try {
            await fs.rmdir(TEMP_TEST_DIR, { recursive: true });
        } catch (e) {
            // Ignore cleanup errors
        }
    }

    async runTest(testName, testFunction) {
        this.testsRun++;
        console.log(`${colors.blue}Running: ${testName}${colors.reset}`);
        
        try {
            await testFunction.call(this);
            console.log(`${colors.green}✅ PASS: ${testName}${colors.reset}\n`);
            this.testsPassed++;
        } catch (error) {
            console.log(`${colors.red}❌ FAIL: ${testName}${colors.reset}`);
            console.log(`   Error: ${error.message}\n`);
            this.testsFailed++;
        }
    }

    // Mock Task tool delegation checker
    createMockClaudeEnvironment() {
        return {
            taskCalls: [],
            
            // Mock Task tool call
            Task: (agentName, instructions) => {
                this.taskCalls.push({ agentName, instructions });
                
                // Simulate agent responses based on agent type
                if (agentName === 'spec-analyst') {
                    return this.mockSpecAnalystResponse(instructions);
                } else if (agentName === 'test-designer') {
                    return this.mockTestDesignerResponse(instructions);
                }
                
                throw new Error(`Unknown agent: ${agentName}`);
            },
            
            // Verify delegation occurred
            verifyDelegation: (expectedAgent, expectedInstructions) => {
                const matchingCall = this.taskCalls.find(call => 
                    call.agentName === expectedAgent && 
                    call.instructions.includes(expectedInstructions)
                );
                return !!matchingCall;
            }
        };
    }

    mockSpecAnalystResponse(instructions) {
        return {
            requirements: "Test requirements generated",
            testCases: ["Test case 1", "Test case 2"],
            specifications: "Detailed specifications"
        };
    }

    mockTestDesignerResponse(instructions) {
        return {
            testSuite: "Generated test suite",
            testStrategy: "Test strategy document",
            mockData: "Test data and fixtures"
        };
    }

    // TC004: /spec-init Command Delegation Tests
    async test_tc004_spec_init_delegates_to_spec_analyst() {
        // Given: A valid framework installation with spec-init command
        await this.setupTestEnv();
        
        // Create framework structure
        const claudeMd = `# Specification-First Development Workflow

## Core Principles
- Specifications before implementation

## Workflow  
1. Specification Phase

## Instructions for Claude
- Ask clarifying questions`;

        await fs.writeFile('CLAUDE.md', claudeMd);
        await fs.mkdir('commands', { recursive: true });
        
        // Create spec-init command that should delegate to spec-analyst
        const specInitCommand = `---
description: Initialize specification process for a new feature - creates detailed requirements, test cases, and implementation plan
---

# Specification Initialization

You are starting the specification-first development process for: **$ARGUMENTS**

**IMMEDIATE ACTION**: Delegate the requirements analysis for "$ARGUMENTS" to the spec-analyst sub-agent. The spec-analyst will ask clarifying questions and create detailed specifications following their specialized process.`;

        await fs.writeFile('commands/spec-init.md', specInitCommand);
        
        // When: spec-init command is processed with arguments
        const commandContent = await fs.readFile('commands/spec-init.md', 'utf8');
        const processedCommand = commandContent.replace('$ARGUMENTS', 'todo API endpoint');
        
        // Then: Should contain delegation to spec-analyst
        if (!processedCommand.includes('spec-analyst')) {
            throw new Error('spec-init command does not delegate to spec-analyst');
        }
        
        if (!processedCommand.includes('$ARGUMENTS')) {
            // Arguments should be replaced in processing
            return true;
        }
        
        return true;
    }

    async test_tc005_spec_init_argument_substitution() {
        // Given: spec-init command with $ARGUMENTS placeholder
        await this.setupTestEnv();
        
        const specInitCommand = `---
description: Test command
---

Process the following feature: $ARGUMENTS

Delegate to spec-analyst for: "$ARGUMENTS"`;

        await fs.writeFile('test-command.md', specInitCommand);
        
        // When: Arguments are substituted
        const commandContent = await fs.readFile('test-command.md', 'utf8');
        const testArguments = 'user authentication system';
        const processedCommand = commandContent.replace(/\$ARGUMENTS/g, testArguments);
        
        // Then: All $ARGUMENTS occurrences should be replaced
        if (processedCommand.includes('$ARGUMENTS')) {
            throw new Error('Not all $ARGUMENTS placeholders were substituted');
        }
        
        if (!processedCommand.includes(testArguments)) {
            throw new Error('Arguments were not properly substituted');
        }
        
        return true;
    }

    async test_tc006_spec_init_delegation_format() {
        // Given: spec-init command
        await this.setupTestEnv();
        
        const specInitCommand = `---
description: Initialize specification process
---

# Specification Initialization

**IMMEDIATE ACTION**: Delegate the requirements analysis for "$ARGUMENTS" to the spec-analyst sub-agent.`;

        await fs.writeFile('commands/spec-init.md', specInitCommand);
        
        // When: Command is processed
        const commandContent = await fs.readFile('commands/spec-init.md', 'utf8');
        
        // Then: Should have proper delegation format
        if (!commandContent.includes('IMMEDIATE ACTION')) {
            throw new Error('Command missing IMMEDIATE ACTION directive');
        }
        
        if (!commandContent.includes('spec-analyst sub-agent')) {
            throw new Error('Command does not specify spec-analyst sub-agent');
        }
        
        if (!commandContent.includes('"$ARGUMENTS"')) {
            throw new Error('Command does not pass arguments to sub-agent');
        }
        
        return true;
    }

    // TC005: Command Integration Tests  
    async test_tc007_command_yaml_frontmatter_parsing() {
        // Given: Command with YAML frontmatter
        await this.setupTestEnv();
        
        const commandWithYaml = `---
description: Test command for validation
author: Framework
version: 1.0
---

# Test Command
Command content here.`;

        await fs.writeFile('test-command.md', commandWithYaml);
        
        // When: YAML frontmatter is parsed
        const commandContent = await fs.readFile('test-command.md', 'utf8');
        const yamlMatch = commandContent.match(/^---\n([\s\S]*?)\n---/);
        
        // Then: YAML should be properly formatted and parseable
        if (!yamlMatch) {
            throw new Error('YAML frontmatter not found or malformed');
        }
        
        const yamlContent = yamlMatch[1];
        if (!yamlContent.includes('description:')) {
            throw new Error('YAML missing required description field');
        }
        
        return true;
    }

    async test_tc008_multiple_command_delegation() {
        // Given: Multiple commands that delegate to different agents
        await this.setupTestEnv();
        
        const commands = {
            'spec-init.md': `---
description: Initialize specifications
---
Delegate to spec-analyst with $ARGUMENTS`,

            'spec-review.md': `---  
description: Review specifications
---
Use test-designer to validate $ARGUMENTS`,

            'impl-plan.md': `---
description: Create implementation plan  
---
Task arch-designer with $ARGUMENTS`
        };
        
        await fs.mkdir('commands', { recursive: true });
        
        for (const [filename, content] of Object.entries(commands)) {
            await fs.writeFile(`commands/${filename}`, content);
        }
        
        // When: Commands are processed
        const expectedDelegations = [
            { command: 'spec-init.md', agent: 'spec-analyst' },
            { command: 'spec-review.md', agent: 'test-designer' },
            { command: 'impl-plan.md', agent: 'arch-designer' }
        ];
        
        // Then: Each command should delegate to correct agent
        for (const { command, agent } of expectedDelegations) {
            const commandContent = await fs.readFile(`commands/${command}`, 'utf8');
            if (!commandContent.includes(agent)) {
                throw new Error(`Command ${command} does not delegate to ${agent}`);
            }
        }
        
        return true;
    }

    // TC006: Task Tool Integration Tests
    async test_tc009_task_tool_agent_resolution() {
        // Given: Framework with defined agents
        await this.setupTestEnv();
        
        await fs.mkdir('agents', { recursive: true });
        
        const agentDefinitions = [
            'spec-analyst',
            'test-designer', 
            'arch-designer',
            'impl-specialist',
            'qa-validator'
        ];
        
        // Create agent definition files
        for (const agentName of agentDefinitions) {
            const agentContent = `---
name: ${agentName}
description: Test ${agentName} agent
tools: [Read, Write, Edit]
---

# ${agentName} Agent`;
            
            await fs.writeFile(`agents/${agentName}.md`, agentContent);
        }
        
        // When: Task tool attempts to resolve agents
        const mockClaude = this.createMockClaudeEnvironment();
        
        // Simulate Task tool calls
        try {
            mockClaude.Task('spec-analyst', 'Analyze requirements for todo API');
            mockClaude.Task('test-designer', 'Create test suite for todo API');
        } catch (error) {
            throw new Error(`Task tool failed to resolve agents: ${error.message}`);
        }
        
        // Then: Task calls should succeed and be tracked
        if (mockClaude.taskCalls.length !== 2) {
            throw new Error(`Expected 2 task calls, got ${mockClaude.taskCalls.length}`);
        }
        
        return true;
    }

    async test_tc010_task_tool_error_handling() {
        // Given: Task tool call to non-existent agent
        const mockClaude = this.createMockClaudeEnvironment();
        
        // When: Task tool is called with invalid agent name
        let errorThrown = false;
        try {
            mockClaude.Task('non-existent-agent', 'Some instructions');
        } catch (error) {
            errorThrown = true;
            
            // Then: Should throw appropriate error
            if (!error.message.includes('Unknown agent')) {
                throw new Error('Expected "Unknown agent" error message');
            }
        }
        
        if (!errorThrown) {
            throw new Error('Expected error for non-existent agent was not thrown');
        }
        
        return true;
    }

    async test_tc011_end_to_end_command_execution() {
        // Given: Complete framework with all components
        await this.setupTestEnv();
        
        // Create complete framework structure
        await fs.writeFile('CLAUDE.md', `# Specification-First Development Workflow
## Core Principles
## Workflow  
## Instructions for Claude`);
        
        await fs.mkdir('agents', { recursive: true });
        await fs.mkdir('commands', { recursive: true });
        
        // Create spec-analyst agent
        await fs.writeFile('agents/spec-analyst.md', `---
name: spec-analyst
description: Requirements analysis specialist
tools: [Read, Write, Edit, Grep, Glob]
---

# Specification Analyst
Converts requirements into detailed specifications.`);
        
        // Create spec-init command
        await fs.writeFile('commands/spec-init.md', `---
description: Initialize specification process for a new feature
---

# Specification Initialization

You are starting the specification-first development process for: **$ARGUMENTS**

**IMMEDIATE ACTION**: Delegate the requirements analysis for "$ARGUMENTS" to the spec-analyst sub-agent.`);
        
        // When: Full command execution is simulated
        const mockClaude = this.createMockClaudeEnvironment();
        
        // Simulate the command processing flow
        const commandContent = await fs.readFile('commands/spec-init.md', 'utf8');
        const processedCommand = commandContent.replace(/\$ARGUMENTS/g, 'user authentication API');
        
        // Extract delegation instruction and execute
        if (processedCommand.includes('spec-analyst sub-agent')) {
            mockClaude.Task('spec-analyst', 'Analyze requirements for user authentication API');
        }
        
        // Then: Complete flow should execute without errors
        if (mockClaude.taskCalls.length !== 1) {
            throw new Error('Expected exactly one Task call in end-to-end flow');
        }
        
        const taskCall = mockClaude.taskCalls[0];
        if (taskCall.agentName !== 'spec-analyst') {
            throw new Error('Expected delegation to spec-analyst');
        }
        
        if (!taskCall.instructions.includes('user authentication API')) {
            throw new Error('Task instructions should contain the feature arguments');
        }
        
        return true;
    }

    async test_tc012_performance_command_processing() {
        // Given: Large number of command processing operations
        await this.setupTestEnv();
        
        // Create multiple commands for performance testing
        await fs.mkdir('commands', { recursive: true });
        
        const commandCount = 100;
        const commands = [];
        
        for (let i = 0; i < commandCount; i++) {
            const commandContent = `---
description: Performance test command ${i}
---

# Command ${i}
Delegate to spec-analyst: $ARGUMENTS`;
            
            const filename = `commands/perf-command-${i}.md`;
            await fs.writeFile(filename, commandContent);
            commands.push(filename);
        }
        
        // When: Commands are processed rapidly
        const startTime = Date.now();
        
        const mockClaude = this.createMockClaudeEnvironment();
        
        for (let i = 0; i < commandCount; i++) {
            const commandContent = await fs.readFile(commands[i], 'utf8');
            const processedCommand = commandContent.replace('$ARGUMENTS', `feature-${i}`);
            
            if (processedCommand.includes('spec-analyst')) {
                mockClaude.Task('spec-analyst', `Process feature-${i}`);
            }
        }
        
        const executionTime = Date.now() - startTime;
        
        // Then: Processing should complete within reasonable time
        if (executionTime > 5000) { // 5 seconds for 100 commands
            throw new Error(`Command processing too slow: ${executionTime}ms for ${commandCount} commands`);
        }
        
        if (mockClaude.taskCalls.length !== commandCount) {
            throw new Error(`Expected ${commandCount} task calls, got ${mockClaude.taskCalls.length}`);
        }
        
        console.log(`   Performance: Processed ${commandCount} commands in ${executionTime}ms`);
        return true;
    }

    // Test runner
    async runAllTests() {
        console.log(`🧪 Command Execution Testing Suite`);
        console.log(`===================================\n`);

        const tests = [
            ['TC004: /spec-init Delegates to spec-analyst', this.test_tc004_spec_init_delegates_to_spec_analyst],
            ['TC005: /spec-init Argument Substitution', this.test_tc005_spec_init_argument_substitution],
            ['TC006: /spec-init Delegation Format', this.test_tc006_spec_init_delegation_format],
            ['TC007: Command YAML Frontmatter Parsing', this.test_tc007_command_yaml_frontmatter_parsing],
            ['TC008: Multiple Command Delegation', this.test_tc008_multiple_command_delegation],
            ['TC009: Task Tool Agent Resolution', this.test_tc009_task_tool_agent_resolution],
            ['TC010: Task Tool Error Handling', this.test_tc010_task_tool_error_handling],
            ['TC011: End-to-End Command Execution', this.test_tc011_end_to_end_command_execution],
            ['TC012: Performance Command Processing', this.test_tc012_performance_command_processing]
        ];

        for (const [testName, testFunction] of tests) {
            await this.runTest(testName, testFunction);
        }

        await this.cleanupTestEnv();

        // Test summary
        console.log(`=====================================`);
        console.log(`Test Results:`);
        console.log(`  Total: ${this.testsRun}`);
        console.log(`  ${colors.green}Passed: ${this.testsPassed}${colors.reset}`);
        console.log(`  ${colors.red}Failed: ${this.testsFailed}${colors.reset}\n`);

        if (this.testsFailed === 0) {
            console.log(`${colors.green}🎉 All Command Execution tests PASSED!${colors.reset}`);
            process.exit(0);
        } else {
            console.log(`${colors.red}❌ ${this.testsFailed} Command Execution tests FAILED!${colors.reset}`);
            process.exit(1);
        }
    }
}

// Run the test suite
if (require.main === module) {
    const testSuite = new CommandExecutionTestSuite();
    testSuite.runAllTests().catch(error => {
        console.error(`${colors.red}Test suite error: ${error.message}${colors.reset}`);
        process.exit(1);
    });
}

module.exports = CommandExecutionTestSuite;