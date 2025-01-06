pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "bootstrap", to: "bootstrap.min.js"
pin "@popperjs/core", to: "popper.js"
# Sortableのピンを追加
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.0/modular/sortable.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers" 
