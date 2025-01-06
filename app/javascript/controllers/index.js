import { Application } from "@hotwired/stimulus"
import { Controller } from "@hotwired/stimulus"
import SpotsRegistrationController from "./spots_registration_controller"
import ScheduleEditorController from "./schedule_editor_controller"

// Stimulusアプリケーションを開始
const application = Application.start()

// ドロップダウンコントローラー
class DropdownController extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle('show')
  }
}

application.register("dropdown", DropdownController)
application.register("spots-registration", SpotsRegistrationController)
application.register("schedule-editor", ScheduleEditorController)

export { application }
