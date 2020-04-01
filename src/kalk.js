let remote = require('electron').remote
let math = require('mathjs')

let error = ''

window.addEventListener('keyup', (event) => {
	const keyName = event.key

	// console.log(keyName)
	// hide calculator on escape click
	if (keyName === 'Escape') {
		remote.getCurrentWindow().hide()
	}

	if (keyName === 'Alt') {
		// console.log(error)
		if (error === '') {
			$("#main-error").css('visibility', 'hidden')
		} else {
			document.getElementById("main-error").innerHTML = error
			$("#main-error").css('visibility', 'visible')
		}
	}
	// make calculation
	else {
		let expression = document.getElementById("main-input-input").value
		let result = ''
		try {
			result = math.eval(expression)
		} catch (err) {
			error = err.message
			console.log(error)
			return
		}
		error = ''
		$("#main-error").css('visibility', 'hidden')
		if (typeof result === "function") {
			return
		}
		document.getElementById("main-result").innerHTML = result === undefined ? '' : result

		// LaTeX
		let mathjaxHelper = require('mathjax-electron')
		let container = document.getElementById("pretty")
		let pretty =  math.parse(expression).toTex({
			parenthesis: 'auto'
		})
		console.log(pretty)
		if (pretty === 'undefined') {
			container.innerHTML = ''
			return
		} else {
			katex.render(pretty, document.getElementById('pretty'), {displayMode: true})
		}
	}
}, false)
