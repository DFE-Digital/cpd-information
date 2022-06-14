function terminalLog(violations) {
  cy.task(
    'log',
    `${violations.length} accessibility violation${
      violations.length === 1 ? '' : 's'
    } ${violations.length === 1 ? 'was' : 'were'} detected`
  )
  // pluck specific keys to keep the table readable
  const violationData = violations.map(
    ({ id, impact, description, nodes }) => ({
      id,
      impact,
      description,
      nodes: nodes.length
    })
  )

  cy.task('table', violationData)
}

let paths = [
  "/",
  "/leading-teaching",
  "/leading-behaviour-and-culture",
  "/leading-literacy",
  "/leading-teacher-development",
  "/senior-leadership",
  "/headship",
  "/executive-leadership",
  "/early-years-leadership"
]

describe('Accessibility', () => {
  paths.forEach(path => {
    it(path + " accessibility", () => {
      cy.visit("http://localhost:3000" + path)
      cy.injectAxe()
      cy.checkA11y(null, null, terminalLog)
    })
  });
})