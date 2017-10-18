# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  class ViewPresenter
    # ViewPresenter helps with view params handling, checks restrictions,
    # handle defauls, and provides handy access.
    #
    # == Tutorial
    #
    # === Views and params
    #
    # The general way of using it it's define +view+ method in your controller
    # like the following example:
    #
    #   def view
    #     ViewPresenter.new(params, {
    #       allowed: {
    #         view: %w(list expanded thumbnail),
    #         order_by: %w(date space),
    #         direction: %w(asc desc)
    #       },
    #       default: {
    #         view: 'list',
    #         order_by: 'date',
    #         direction: 'desc',
    #         page: '1'
    #       }
    #     })
    #   end
    #   helper_method :view
    #
    # In our app, we have +view+ already defined in ApplicationController, so
    # the best way of using it is the following:
    #
    # In your Model define constant +LIST_OPTIONS+, let's use FileInfo model as
    # the example.
    #
    #   LIST_OPTIONS = {
    #     allowed: {
    #       view: %w(list expanded thumbnail),
    #       order_by: %w(date file_type),
    #       direction: %w(asc desc)
    #     },
    #     default: {
    #       view: 'list',
    #       order_by: 'date',
    #       direction: 'desc',
    #       page: '1',
    #       entry_name: 'file'
    #     }
    #   }.freeze
    #
    # In your controller define protected method +list_options+ like the
    # following example:
    #
    #   protected
    #   def list_options
    #     FileInfo::LIST_OPTIONS
    #   end
    #
    # To show our sorting/grouping control, add into your view or helper code
    # as following example:
    #
    #   view_options_menu([
    #     { name: 'Date',      asc: 'oldest on top', desc: 'newest on top', order_by: 'date',      direction: 'desc' },
    #     { name: 'File type', asc: 'A-Z',           desc: 'Z-A',           order_by: 'file_type', direction: 'asc' }
    #   ])
    #
    # ...this code will render a drop-down menu with _Date_ and _File type_ options. These options will automatically handle their
    # direction status, will have proper links, etc.
    #
    # === Tabs
    #
    # One more feature is handling current tab (aka blue bubbles) and dynamicly
    # adding new ones.
    #
    # To define primary tabs use +primary_tabs+ helper like the following
    # example:
    #
    #   primary_tabs([
    #     { name: 'Day',    tab: 'day',    href: "#day_calendar" },
    #     { name: 'Week',   tab: 'week',   href: "#week_calendar" },
    #     { name: 'Month',  tab: 'month',  href: "#month_calendar" },
    #     { name: 'Agenda', tab: 'agenda', href: space_agenda_path(tab: 'agenda') }
    #   ])
    #
    # To ask what tab is active now do
    #
    #   view.tab              # => 'day'
    #
    # To explicitly set current active tab just set value use need
    #
    #   view.tab = 'search'
    #
    # That's all. From now on you can use +view+ method in your controllers,
    # helpers and views.
    #
    # When use pagination will be good idea to add +:entry_name+ to your
    # LIST_OPTIONS, this name will be used by +will_paginate+ for rendering
    # description of pages.
    #
    # == Examples
    #
    # Get current view:
    #
    #   view.current          # => 'list'
    #   view.to_s             # => 'list'
    #   view.to_param         # => 'list'
    #   view.all              # => [ 'list', 'expanded', 'thumbnail' ]
    #
    # Check what you have:
    #
    #   view.current?('list') # => true
    #   view.list?            # => true
    #   view.expanded?        # => false
    #
    # Check what direction is in use now:
    #
    #   view.direction.asc?   # => true
    #   view.direction.desc?  # => false
    #
    # Get other params:
    #
    #   view.page             # => '1'
    #   view.order_by         # => 'data'
    #   view.direction        # => 'asc'
    #
    # Get all params:
    #
    #   view.params
    #
    # ...these params will have passed params merged into default ones.

    DEFAULT_OPTIONS = {
      allowed: { view: %w(list) },
      default: { view: "list", entry_name: "item" }
    }
    # Instantiates ViewPresenter. We already have it in ApplicationController,
    # so +view+ method as described above is available in all controllers.
    # Accepts two hashes - +params+ and +options+, where +params+ is Rails'
    # params, and options is allowed/default options hash.
    def initialize(params = {}, options = {})
      @cfg = DEFAULT_OPTIONS.dup.merge(options).with_indifferent_access
      restriction = lambda do |key, old_value, new_value|
        if @cfg[:allowed][key].nil? || @cfg[:allowed][key].include?(new_value)
          new_value
        else
          old_value
        end
      end
      parsed = {}.merge!(@cfg[:default], &restriction)
      parsed.merge!(params.stringify_keys || {}, &restriction)
      parsed.reject! { |key, value| (key == "action") || (key == "controller") }
      @params = parsed.with_indifferent_access
      self
    end

    # Attribute accessor to the ViewPresenter's +@params+ instance variable.
    attr_reader :params

    # Returns currently selected view as string.
    # This method is aliased to +to_s+ and +to_param+ methods.
    #
    #   view.current  # => 'list'
    #   view.to_s     # => 'list'
    #   view.to_param # => 'list'
    #--
    # TBD:
    # Allows view.current.list? (really required?)
    # Wrap all strings returned by view into string inquirer for consistency?
    #++
    def current
      ActiveSupport::StringInquirer.new(@params[:view].is_a?(Array) ?
                                        @params[:view].join("") :
                                        @params[:view].to_s)
    end
    alias_method :to_s, :current
    alias_method :to_param, :current

    # Returns eighter +true+ or +false+ if passed string is equal to current view name.
    # This methods prevents us having method +current+ so keep it in mind.
    #
    #   view.current?('list')     # => true
    #   view.current?('expanded') # => false
    def current?(v)
      current == v.to_s
    end

    # Enables dynamis checking of view params like +view.list?+.
    #
    #   view.list?           # => true
    #   view.expanded?       # => false
    #   view.direction.asc?  # => true
    #   view.direction.desc? # => false

    # Returns all view params as array of strings.
    #
    #   view.all # => [ 'list', 'expanded', 'thumbnail' ]
    #--
    # TBD:
    # Need to wrap all views to inquirer?
    # Special object similar to inquirer for each view?
    # view.all { |v| Rails.logger.info v.current?, v.list? }
    #++
    def all
      @cfg[:allowed][:view]
    end

    # Returns all allowed params as hash.
    #
    #   view.allowed # => { "view" => ["list", "expanded", "thumbnail"], "sview" => ["week", "month"] }
    def allowed
      @cfg[:allowed]
    end

    # Returns currently seleted secondary view as string wich is presented in params as +sview+.
    #
    #   view.sview # => 'week'
    def sview
      ActiveSupport::StringInquirer.new(@params[:sview]) unless @params[:sview].nil?
    end

    # Returns current page number as string if you use +will_pagination+ and have passed
    # +:page+ param to the ViewPresenter.
    #
    #   view.page # => '1'
    def page
      # extract :page from defaults? no need using default page?
      @params[:page].to_i > 0 ? @params[:page] : @cfg[:default][:page]
    end

    # TODO: if no start/length, look for page and per_page
    # Returns length as specified by the query in params as +length+.
    # Must be a non-negative integer.
    #
    #   view.length # => 10
    def length
      # TODO: add a default for length if not in params (instead of just 5!)
      @params[:length].to_i > 0 ? @params[:length].to_i : 5 # or use @cfg[:default][:length].to_i
    end

    # Returns offset as specified by the query in params as +start+.
    # Must be a non-negative integer.
    #
    #   view.start # => 5
    def start
      @params[:start].to_i > 0 ? @params[:start].to_i : 0
    end

    # Returns current ordering as string wich is presented in params as +order_by+.
    #
    #   view.order_by # => 'date'
    def order_by
      ActiveSupport::StringInquirer.new(@params[:order_by]) unless @params[:order_by].nil?
    end

    # Returns current grouping as string wich is presented in params as +group_by+.
    #
    #   view.group_by # => 'file_type'
    def group_by
      ActiveSupport::StringInquirer.new(@params[:group_by]) unless @params[:group_by].nil?
    end

    # Returns direction or ordering as string shortcuts +asc+ and +desc+.
    #
    #   view.direction # => 'asc'
    def direction
      @params[:direction].nil? ? nil : @params[:direction].to_sym
    end

    # Returns currently seleted primary tab (aka blue bubble) as string.
    #
    #   view.tab # => 'day'
    def tab
      ActiveSupport::StringInquirer.new(@params[:tab]) unless @params[:tab].nil?
    end

    # Check if selected tab is default.
    def default_tab?
      tab == @cfg[:default][:tab]
    end

    # Allows to set currently selected tab. Pass it name of the tab as string.
    #
    #   view.tab = 'search'
    #--
    # Temporary hack for separate "Search results" tab in _cnavigation.hml.erb.
    # TODO: remove, once decision made on extra "Search" tab
    #++
    def tab=(name)
      @params.merge!("tab" => name)
    end

    # Returns the filter hash
    #
    # view.filter # => {'id' => ["1","2","3"]}
    #
    def filter
      @params[:filter]
    end

    # Returns currently seleted secondary tab as string.
    #
    #   view.stab # => 'releases'
    def stab
      ActiveSupport::StringInquirer.new(@params[:stab]) unless @params[:stab]
    end

    def tags_filter
      @params[:tags_filter]
    end

    def tags_applied?
      !tags_filter.blank?
    end
  end
end
