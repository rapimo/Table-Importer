
require 'spec_helper.rb'


describe "TableImporter "do

  describe "A Symple Hash" do
    before :each do
      @dict = {"Contact" =>{:first_name=>:col1,:last_name=>:col2,:full_name=>[:colA,:colB,lambda{|f,l| "#{f} #{l}"}]}}
      @data = [["Bob","Marley"]]

      @mapper = TableImporter::Mapper.new(@dict)
      @importer = TableImporter::Importer.new
      @importer.data =@data
      @importer.mapper = @mapper
      
      @result = @importer.build

    end

    it "should call block for get_value" do
      @importer.get_value("Foo","Bar",lambda{|v1,v2| "#{v1} -- #{v2}"}).should == "Foo -- Bar"
    end
    it "should return value for get_value" do
      @importer.get_value("Foo").should == "Foo"
    end

    it "should create a Contact " do
      @result.should == [[Contact.new("Bob","Marley", "Bob Marley")]]
    end
    it "should assign Bob as first_name" do
      @result.flatten.first.first_name.should == "Bob"
    end
  end

  describe "Reflections" do
    before :each do
      
      ref_address = double("Reflection",:macro=> :has_one,:class_name=>"Address")
      ref_user = double("Reflection",:macro=> :belongs_to,:class_name=>"User")
      ref_tags = double("Reflection",:macro=> :has_many,:class_name=>"Tag")

      reflections = {:address=>ref_address,:user=>ref_user,:tags=>ref_tags}
      Contact.stub(:reflections).and_return(reflections)

      @contact = Contact.new("Bob")
      @address = Address.new("First Avenue","12345","New York")
      @contact.address = @address
      @user = User.new("Ann")
      @contact.user = @user
      @tags = [Tag.new("Friends"),Tag.new("School"),Tag.new("Private")]
      @contact.tags=@tags

      @dict = {"Contact" =>{:first_name=>:col1,:address => {:street=>:col2,:zip=>:col3,:city=>:col4}}}
      @dict["Contact"].merge!({:user => {:name=>:col5},:tags=>{:tagging=>[:col6,:col7,:col8]}})
      @mapper = TableImporter::Mapper.new(@dict)

      @data = [["Bob","First Avenue","12345","New York","Ann","Friends","School","Private"]]
      @importer = TableImporter::Importer.new
      @importer.data =@data
      @importer.mapper = @mapper
      @result = @importer.build
    end
    it "should create a Contact " do
      @result.should == [[@contact]]
    end
    it "should assign Bob as first_name" do
      @result.flatten.first.first_name.should == "Bob"
    end
    it "should assign the address reflection" do
      @result.flatten.first.address.should == @address
      end
    it "should assign the user reflection" do
      @result.flatten.first.user.should == @user
      end
    it "should assign the tags reflection" do
      @result.flatten.first.tags.should == @tags
    end
  end

  describe "Nested Reflections" do
    before :each do

      ref_user = double("UserReflection",:macro=> :belongs_to,:class_name=>"User")
      Contact.stub(:reflections).and_return({:user=>ref_user})

      ref_address = double("AddressReflection",:macro=> :has_one,:class_name=>"Address")
      User.stub(:reflections).and_return({:address=>ref_address})

      ref_tags = double("TagReflection",:macro=> :has_many,:class_name=>"Tag")
      Address.stub(:reflections).and_return(:tags=>ref_tags)
      
      @contact = Contact.new("Bob")
      @address = Address.new("First Avenue","12345","New York")
      @user = User.new("Ann",@address)
      @contact.user = @user

      @tags = [Tag.new("Friends","Today"),Tag.new("School","Today"),Tag.new("Private","Today")]
      @address.tags = @tags

      @dict = {"Contact" =>{:first_name=>:col1,:user => {:name=>:col5, :address => {:street=>:col2,:zip=>:col3,:city=>:col4 ,
                                                     :tags => {:tagging=>[:col6,:col8,:col10],:created_at=>[:col7,:col9,:col11]}}}}}
      @mapper = TableImporter::Mapper.new(@dict)

      @data = [["Bob","First Avenue","12345","New York","Ann","Friends","Today","School","Today","Private","Today"]]
      @importer = TableImporter::Importer.new
      @importer.data =@data
      @importer.mapper = @mapper
      @result = @importer.build

    end

    it "should build the complex contact object" do
      @result.flatten.first.should == @contact
    end

    it "should assign the user to contact " do
      @result.flatten.first.user.should == @user
    end

    it "should assign the contact users address" do
      @result.flatten.first.user.address.should == @address
    end
    it "should assign the tag list to the address" do
      @result.flatten.first.user.address.tags.should == @tags
    end

  end


end

