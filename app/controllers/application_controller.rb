class ApplicationController < ActionController::Base
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :null_session

    def run_with_rescue
        begin
            yield
        rescue ScriptError => e
            render_error('Something went wrong')
            puts e.to_s
            puts e.backtrace[0..10].join("\n")
        rescue => e
            render_error(e)
            puts e.to_s
        end
    end

    def render_error(e)
        render :json => {success: false, message: e.to_s}
    end

    def render_success(payload)
        render :json => {success: true, message: nil}.merge(payload)
    end
end
