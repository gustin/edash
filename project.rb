require 'pstore'
require 'md5'
require 'json'

module Dashboard
  class Project
    class << self
      def init_store(env)
        @store = PStore.new(File.dirname(__FILE__)+'/dashboard-'+ env +'.pstore')
      end

      def store
        @store
      end

      def all
        projects = {}
        store.transaction do
          store.roots.each do |name|
            projects[name] = store[name]
          end
        end
        projects.sort
      end

      def save(project)
        store.transaction do
          store[project.name] = project
        end
      end
    end

    attr_reader :name, :author, :status, :author_gravatar

    def <=>(other)
      self.name <=> other.name
    end

    def initialize(params)
      @name = params['project']
      @author = params['author']
      @status = params['status']

      if (params['author'] && params['author'].size > 0)
        @author_gravatar = gravatar_from(params['author'])
      end
    end

    def gravatar_from(author)
      "http://www.gravatar.com/avatar/#{MD5::md5(author.match(/<(.*)>/)[1].gsub(' ', '+'))}?s=50"
    end

    def to_json(*a)
      {
        'json_class'   => self.class.name,
        'name' => name,
        'author' => author,
        'status' => status, 
        'author_gravatar' => author_gravatar
      }.to_json(*a)
    end
  end
end
