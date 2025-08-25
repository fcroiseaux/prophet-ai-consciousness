# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Universal Development Guidelines

### Code Quality Standards
- Write clean, readable, and maintainable code
- Follow consistent naming conventions across the project
- Use meaningful variable and function names
- Keep functions focused and single-purpose
- Add comments for complex logic and business rules

### Git Workflow
- Use descriptive commit messages following conventional commits format
- Create feature branches for new development
- Keep commits atomic and focused on single changes
- Use pull requests for code review before merging
- Maintain a clean commit history

### Documentation
- Keep README.md files up to date
- Document public APIs and interfaces
- Include usage examples for complex features
- Maintain inline code documentation
- Update documentation when making changes

### Code Validation
- Validate functionality manually before committing
- Check for edge cases and error handling
- Ensure new features work as expected
- Verify integration with existing code

### Security Best Practices
- Never commit sensitive information (API keys, passwords, tokens)
- Use environment variables for configuration
- Validate input data and sanitize outputs
- Follow principle of least privilege
- Keep dependencies updated

## Project Structure Guidelines

### File Organization
- Group related files in logical directories
- Use consistent file and folder naming conventions
- Separate source code from configuration files
- Keep build artifacts out of version control
- Organize assets and resources appropriately

### Configuration Management
- Use configuration files for environment-specific settings
- Centralize configuration in dedicated files
- Use environment variables for sensitive or environment-specific data
- Document configuration options and their purposes
- Provide example configuration files

## Development Workflow

### Before Starting Work
1. Pull latest changes from main branch
2. Create a new feature branch
3. Review existing code and architecture
4. Plan the implementation approach

### During Development
1. Make incremental commits with clear messages
2. Build and validate changes frequently
3. Follow established coding standards
4. Update documentation as needed

### Before Submitting
1. Build and validate all changes
2. Check code quality and formatting
3. Update documentation if necessary
4. Create clear pull request description

## Common Patterns

### Error Handling
- Use appropriate error handling mechanisms for the language
- Provide meaningful error messages
- Log errors appropriately for debugging
- Handle edge cases gracefully
- Don't expose sensitive information in error messages

### Performance Considerations
- Profile code for performance bottlenecks
- Optimize database queries and API calls
- Use caching where appropriate
- Consider memory usage and resource management
- Monitor and measure performance metrics

### Code Reusability
- Extract common functionality into reusable modules
- Use dependency injection for better testability
- Create utility functions for repeated operations
- Design interfaces for extensibility
- Follow DRY (Don't Repeat Yourself) principle

## Review Checklist

Before marking any task as complete:
- [ ] Code follows established conventions
- [ ] Code builds without errors
- [ ] Documentation is updated
- [ ] Security considerations are addressed
- [ ] Performance impact is considered
- [ ] Code is reviewed for maintainability

## Swift/iOS Development Guidelines

### Language & Framework
- Swift 5.9+ with SwiftUI for all UI components
- Minimum deployment target: iOS 17.0
- Follow Swift API Design Guidelines
- Use structured concurrency (async/await) for asynchronous operations

### Project Structure
```
Prophet/
├── Models/          # Data models (Codable structs)
├── Views/           # SwiftUI views
├── ViewModels/      # ObservableObject view models (MVVM pattern)
├── Services/        # API services and managers
├── Utilities/       # Helper functions and extensions
└── Resources/       # Assets, JSON files, Info.plist
```

### Swift Coding Standards
- Use `@Published` properties in ViewModels for UI updates
- Implement proper error handling with Result types or throws
- Use `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` appropriately
- Follow MVVM architecture pattern consistently
- Use dependency injection for testability

### Xcode Workflow
- Build command: `xcodebuild -project xcode/Prophet/Prophet.xcodeproj -scheme Prophet -configuration Debug build`
- Clean build: `xcodebuild clean build -project xcode/Prophet/Prophet.xcodeproj -scheme Prophet`
- Run in simulator: Build in Xcode and run on selected simulator

### API Integration
- OpenAI API for chat completions (GPT-4)
- ElevenLabs API for text-to-speech
- Store API keys securely in Keychain, never in code
- Use URLSession for network requests

### SwiftUI Best Practices
- Keep views small and focused
- Extract reusable components
- Use ViewModifiers for common styling
- Implement proper @State and @Binding data flow
- Use NavigationStack for navigation (iOS 16+)

### Audio Handling
- Use AVFoundation for audio playback
- Implement proper AVAudioSession configuration
- Handle audio interruptions gracefully
- Queue audio playback for sequential TTS responses

### Data Persistence
- Consider SwiftData for iOS 17+ or Core Data for broader compatibility
- Use UserDefaults only for simple settings
- Store sensitive data in Keychain

### Code Validation
- Build frequently to catch compilation errors
- Test functionality in simulator or on device
- Verify API integrations work correctly
- Check audio playback functionality

### Common Tasks
- To add a new view: Create in Views/, connect to ViewModel
- To add API endpoint: Extend appropriate Service class
- To add new Prophet feature: Update Prophet model, ViewModel, and View
- To verify audio: Use Simulator or real device (audio doesn't work well in SwiftUI previews)