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
      nodes: nodes.map(n => n.target.join(', ')).join(' | ')
    })
  )

  cy.task('table', violationData)
}

let paths = [
  "/",
  "/accessibility-statement",
  "/cookies",
  "/early-headship-coaching-offer",
  "/early-years-leadership",
  "/executive-leadership",
  "/find-your-teaching-school-hub",
  "/get-a-teacher-reference-number",
  "/headship",
  "/leading-behaviour-and-culture",
  "/leading-literacy",
  "/leading-teacher-development",
  "/leading-teaching",
  "/privacy",
  "/senior-leadership"
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
