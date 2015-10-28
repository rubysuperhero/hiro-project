module StatusObject
  def self.included(base)
    base.extend ClassDefinitions

    base.class_eval do
      attr_reader :id, :name
      def initialize(id)
        @id = id
        @name = self.class.name_for(id)
      end

      def display
        name.titleize
      end

      const_get(:VALUES).each do |name,val|
        define_method(:"#{name}?") { @id == val }
      end
    end
  end

  # # vals = VALUES
  #     attr_reader :id, :name
  #     def initialize(id)
  #       @id = id
  #       @name = vals.invert[id]
  #     end

  #     @@values.each do |name,val|
  #       define_method(:"#{name}?") { id == val }
  #     end

  module ClassDefinitions

    if method_defined?(:values)
      values # =>
    end


    def self.extended(base)
      base.instance_eval do

        values = base::VALUES

        values.each do |name, val|
          const_set(name.to_s.upcase.to_sym, val) # => 0, 1, 2, 3, 4
          base.send(:define_method, name) { val }
        end

        def ids
          @ids ||= const_get(:VALUES).values
        end

        def names
          @names ||= const_get(:VALUES).keys.map(&:to_s)
        end

        def id_map
          const_get(:VALUES)
        end

        def name_map
          @name_map ||= const_get(:VALUES).invert.with_indifferent_access
        end

        def by_id(id=ids.first)
          new(id)
        end

        def id_for(name=names.first)
          id_map.fetch(name, nil)
        end

        def by_name(name=names.first)
          new(id_for name)
        end

        def name_for(id=ids.first)
          name_map.fetch(id, nil).to_s
        end

        def display_for(id=ids.first)
          name_for(id).titleize
        end

        def all
          ids.map do |id|
            new id
          end
        end

        def options_for_select
          ids.map do |i|
            [new(i).display, i]
          end
        end
      end
    end
  end

  # def self.extended(base)
  #   base.instance_eval <<-INST
  #     @mapping = {}
  #     class << self
  #       attr_reader :mapping
  #     end
  #   INST

  #   base.constants.each do |c|
  #     val = base.const_get(c)
  #     base.instance_eval <<-INST
  #       @#{c.downcase} = #{val}
  #       @mapping.merge!(@#{c.downcase} => '#{c.downcase}')

  #       class << self
  #         attr_reader :#{c.downcase}
  #       end
  #     INST
  #   end

  #   base.instance_eval <<-INST
  #     @ids = @mapping.keys
  #     @names = @mapping.values

  #     @id_map = @mapping.invert.with_indifferent_access
  #     @name_map = @mapping
  #     class << self
  #       attr_reader :ids, :names, :id_map, :name_map
  #     end
  #   INST

  #   base.class_eval <<-"CLASS"
  #       def self.by_id(id=ids.first)
  #         new(id)
  #       end

  #       def self.by_name(name=names.first)
  #         by_id(id_for name)
  #       end

  #       def self.id_for(name=names.first)
  #         id_map.fetch name
  #       end

  #       def self.name_for(id=ids.first)
  #         name_map.fetch id
  #       end

  #       def self.options_for_select
  #         id_map.map do |name,id|
  #           [new(id).display, id]
  #         end
  #       end

  #     attr_accessor :id, :name
  #     def initialize(id=self.class.ids.first)
  #       @id = id
  #       @name = self.class.name_for(id)
  #     end

  #     def display
  #       name.gsub(/_+/, ' ').split(/\\s+/).map(&:capitalize).join(' ')
  #     end
  #   CLASS

  #   base.constants.each do |c|
  #     base.class_eval <<-"CLASS"
  #       def #{c.downcase}?
  #         id == #{c}
  #       end
  #     CLASS
  #   end
  # end

end

# class TestAutoGeneratingEverything
#   class << self
#     attr_reader :values

#     def values # !> method redefined; discarding old values
#       {
#         imported:   0,
#         walked:     1,
#         worked:     2,
#         completed:  3,
#         hidden:     4,
#       }
#     end
#   end

#   VALUES = {
#     imported:   0,
#     walked:     1,
#     worked:     2,
#     completed:  3,
#     hidden:     4,
#   }

#   # @mapping = Mash.new
#   # constants.each do |c|
#   #   ap name: name, constant_name: c
#   # end
#   include StatusObject
# end

# TestAutoGeneratingEverything.values # => {:imported=>0, :walked=>1, :worked=>2, :completed=>3, :hidden=>4}

# TestAutoGeneratingEverything.ids # => [0, 1, 2, 3, 4]
# TestAutoGeneratingEverything.names # => ["imported", "walked", "worked", "completed", "hidden"]
# TestAutoGeneratingEverything.id_map # => {:imported=>0, :walked=>1, :worked=>2, :completed=>3, :hidden=>4}
# TestAutoGeneratingEverything.name_map # => <Mash 0=:imported 1=:walked 2=:worked 3=:completed 4=:hidden>

# TestAutoGeneratingEverything::IMPORTED # => 0
# TestAutoGeneratingEverything.imported # =>
# TestAutoGeneratingEverything.walked # =>
# TestAutoGeneratingEverything.worked # =>
# TestAutoGeneratingEverything.completed # =>
# TestAutoGeneratingEverything.hidden # =>

# i = TestAutoGeneratingEverything.new(2) # =>
# i.imported? # =>
# i.walked? # =>
# i.worked? # =>
# i.completed? # =>
# i.hidden? # =>

# # ~> -:211:in `<main>': undefined method `imported' for TestAutoGeneratingEverything:Class (NoMethodError)
