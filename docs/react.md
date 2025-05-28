# What is React?

[React](https://react.dev/) is a popular open-source JavaScript library for building user interfaces, especially single-page applications (SPAs). It enables developers to create reusable UI components and efficiently update the UI in response to data changes using a virtual DOM.

## Key Features

- **Component-Based:** Build encapsulated components that manage their own state.
- **Declarative:** Describe what the UI should look like for any given state.
- **Efficient Updates:** Uses a virtual DOM to minimize direct DOM manipulation.
- **Ecosystem:** Large ecosystem with tools for routing, state management, and more.

## Why Isn't React Used in This Project's Frontend?

Although React is a standard choice for modern web frontends, **this project's frontend does not use React** for the following reasons:

- The frontend may be implemented using plain HTML, CSS, and JavaScript, or another framework.
- The project requirements may not need the complexity or features provided by React.
- Simpler or server-rendered approaches may be preferred for maintainability or performance.
- The codebase or team may have chosen a different technology stack for the UI.

If you see references to React in the documentation or code, they may be legacy, experimental, or placeholder code.  
**If you wish to use React, ensure your frontend is set up with the necessary dependencies and configuration.**

## How to Serve a Production Build Locally

If you see a permissions error when running `npm install -g serve`, you can:

- Use `sudo` to install globally (Linux/macOS):
  ```bash
  sudo npm install -g serve
  ```
- Or, use `npx` to run without installing globally:
  ```bash
  npx serve -s build
  ```

This will serve your React production build from the `build` directory.

---
