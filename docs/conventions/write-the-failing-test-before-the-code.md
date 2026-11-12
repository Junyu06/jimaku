# Write the failing test before the code

Every change to logic starts with a test that fails for the right reason. Then write the least code that makes it pass, then clean up with the tests green.

- Logic lives in JimakuCore so it can be tested with `swift test` on a Mac. If something is hard to test, move the decision into JimakuCore and leave the app or extension target with glue only.
- Run the new test and see it fail before writing the implementation. A test that has never failed has not shown that it can.
- Tests use Swift Testing (`import Testing`).
- Behavior that only the system can produce, such as screen broadcast, Picture in Picture, and background execution, cannot be proven by a unit test. It is verified on a physical device and recorded as a case under `docs/cases/`. A simulator run of such behavior counts as a simulation.
