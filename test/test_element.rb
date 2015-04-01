require 'sdf/test'

module SDF
    describe Element do
        describe "#full_name" do
            attr_reader :xml
            before do
                @xml = REXML::Document.new("<root><parent name=\"p\"><child name=\"c\" /></parent></root>").
                    root
            end

            it "returns the name if there is no parent" do
                xml = REXML::Document.new("<e name=\"p\" />")
                element = Element.new(xml.root)
                assert_equal 'p', element.full_name
            end

            it "returns the name if the parent has no name" do
                xml = REXML::Document.new("<root><e name=\"p\" /></root>")
                # This is because all SDF elements have a name except the root
                root = Element.new(xml.root)
                element = Element.new(xml.root.elements.first, root)
                assert_equal 'p', element.full_name
            end

            it "combines the parent and child names to form the full name, recursively" do
                xml = REXML::Document.new("<root><e name=\"0\"><e name=\"1\"><e name=\"p\" /></e></e></root>")
                # This is because all SDF elements have a name except the root
                el0 = Element.new(xml.root.elements.first)
                el1 = Element.new(el0.xml.elements.first, el0)
                elp = Element.new(el1.xml.elements.first, el1)
                assert_equal '0.1.p', elp.full_name
            end
        end

        describe "#child_by_name" do
            describe "required child" do
                attr_reader :element
                before do
                    xml = REXML::Document.new("<e name=\"0\"><e name=\"0.1\" /><e name=\"0.2\" /></e>")
                    @element = Element.new(xml.root)
                end

                it "creates a child of the specified class if there is exactly one XML element matching" do
                    child_xml = element.xml.elements.to_a('e[@name=0.1]').first
                    klass = flexmock
                    klass.should_receive(:new).
                        with(child_xml, element).
                        once.
                        and_return(obj = flexmock)
                    assert_equal obj, element.child_by_name('e[@name=0.1]', klass)
                end
                it "raises if there is more than one match" do
                    assert_raises(Invalid) do
                        element.child_by_name('e', flexmock)
                    end
                end
                it "raises if there is no match and required is true" do
                    assert_raises(Invalid) do
                        element.child_by_name('does_not_exist', flexmock)
                    end
                end
                it "creates a new element if there is no match and required is false" do
                    klass = flexmock
                    klass.should_receive(:new).
                        with(FlexMock.any, element).
                        once.
                        and_return(obj = flexmock)
                    assert_equal obj, element.child_by_name('default_element', klass, false)
                end
            end
        end
    end
end
