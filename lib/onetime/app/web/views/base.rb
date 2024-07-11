require_relative 'helpers'
require_relative 'secret_elements'

module Onetime
  class App
    class View < Mustache
      include Onetime::App::Views::Helpers
      self.template_path = './templates/web'
      self.view_namespace = Onetime::App::Views
      self.view_path = './app/web/views'
      attr_reader :req, :plan, :is_paid
      attr_accessor :sess, :cust, :locale, :messages, :form_fields
      def initialize req=nil, sess=nil, cust=nil, locale=nil, *args # rubocop:disable Metrics/MethodLength
        @req, @sess, @cust, @locale = req, sess, cust, locale
        @locale ||= req.env['ots.locale'] || OT.conf[:locales].first.to_s || 'en'
        @messages = { :info => [], :error => [] }
        self[:js], self[:css] = [], []
        self[:is_default_locale] = OT.conf[:locales].first.to_s == locale
        self[:supported_locales] = OT.conf[:locales]
        self[:authentication] = OT.conf[:site][:authentication]
        self[:description] = i18n[:COMMON][:description]
        self[:keywords] = i18n[:COMMON][:keywords]
        self[:ot_version] = OT::VERSION.inspect
        self[:ruby_version] = "#{OT.sysinfo.vm}-#{OT.sysinfo.ruby.join}"
        self[:authenticated] = sess.authenticated? if sess
        self[:display_promo] = false
        self[:display_feedback] = false
        self[:colonel] = cust.role?(:colonel) if cust
        self[:feedback_text] = i18n[:COMMON][:feedback_text]
        self[:base_domain] = OT.conf[:site][:domain]
        self[:is_subdomain] = ! req.env['ots.subdomain'].nil?
        self[:no_cache] = false
        self[:display_sitenav] = true
        self[:jsvars] = []
        self[:jsvars] << jsvar(:shrimp, sess.add_shrimp) if sess
        self[:jsvars] << jsvar(:custid, cust.custid)
        self[:jsvars] << jsvar(:email, cust.email)
        self[:display_links] = false
        self[:display_options] = true
        self[:display_recipients] = sess.authenticated?
        self[:display_masthead] = true
        if self[:is_subdomain]
          tmp = req.env['ots.subdomain']
          self[:subdomain] = tmp.to_hash
          self[:subdomain]['homepage'] = '/'
          self[:subdomain]['company_domain'] = tmp.company_domain || 'onetimesecret.com'
          self[:subdomain]['company'] = "Onetime Secret"
          self[:subtitle] = self[:subdomain]['company'] || self[:subdomain]['company_domain']
          self[:display_feedback] = sess.authenticated?
          self[:display_faq] = false
          self[:actionable_visitor] = sess.authenticated?
          self[:override_styles] = true
          self[:primary_color] = req.env['ots.subdomain'].primary_color
          self[:secondary_color] = req.env['ots.subdomain'].secondary_color
          self[:border_color] = req.env['ots.subdomain'].border_color
          self[:banner_url] = req.env['ots.subdomain'].logo_uri
          self[:display_otslogo] = self[:banner_url].to_s.empty?
          self[:with_broadcast] = false
        else
          self[:subtitle] = "One Time"
          self[:display_faq] = true
          self[:display_otslogo] = true
          self[:actionable_visitor] = true
          # NOTE: uncomment the following line to show the broadcast
          #self[:with_broadcast] = ! self[:authenticated]
        end
        unless sess.nil?
          self[:gravatar_uri] = gravatar(cust.email) unless cust.anonymous?

          if cust.pending? && self.class != Onetime::App::Views::Shared
            add_message i18n[:COMMON][:verification_sent_to] + " #{cust.custid}."
          else
            add_error sess.error_message!
          end

          add_message sess.info_message!
          add_form_fields sess.get_form_fields!
        end
        @plan = Onetime::Plan.plan(cust.planid) unless cust.nil?
        @plan ||= Onetime::Plan.plan('anonymous')
        @is_paid = plan.paid?
        init *args if respond_to? :init
      end
      def i18n
        pagename = self.class.name.split('::').last.downcase.to_sym
        @i18n ||= {
          locale: self.locale,
          default: OT.conf[:locales].first.to_s,
          page: OT.locales[self.locale][:web][pagename],
          COMMON: OT.locales[self.locale][:web][:COMMON]
        }
      end
      def setup_plan_variables
        Onetime::Plan.plans.each_pair do |planid,plan|
          self[plan.planid] = {
            :price => plan.price.zero? ? 'Free' : plan.calculated_price,
            :original_price => plan.price.to_i,
            :ttl => plan.options[:ttl].in_days.to_i,
            :size => plan.options[:size].to_i,
            :api => plan.options[:api] ? 'Yes' : 'No',
            :name => plan.options[:name],
            :planid => planid
          }
          self[plan.planid][:price_adjustment] = (plan.calculated_price.to_i != plan.price.to_i)
        end

        @plans = [:individual_v1, :professional_v1, :agency_v1]

        unless cust.anonymous?
          plan_idx = case cust.planid
          when /personal/
            0
          when /professional/
            1
          when /agency/
            2
          end
          @plans[plan_idx] = cust.planid unless plan_idx.nil?
        end
        self[:default_plan] = self[@plans.first.to_s] || self['individual_v1']
        OT.ld self[:default_plan].to_json
        self[:planid] = self[:default_plan][:planid]
      end
      def get_split_test_values testname
        varname = "#{testname}_group"
        if OT::SplitTest.test_running? testname
          group_idx = cust.get_persistent_value sess, varname
          if group_idx.nil?
            group_idx = OT::SplitTest.send(testname).register_visitor!
            OT.info "Split test visitor: #{sess.sessid} is in group #{group_idx}"
            cust.set_persistent_value sess, varname, group_idx
          end
          @plans = *OT::SplitTest.send(testname).sample!(group_idx.to_i)
        else
          @plans = yield # TODO: not tested
        end
      end
      def add_message msg
        messages[:info] << msg unless msg.to_s.empty?
      end
      def add_error msg
        messages[:error] << msg unless msg.to_s.empty?
      end
      def add_form_fields hsh
        (self.form_fields ||= {}).merge! hsh unless hsh.nil?
      end
    end
  end
end
