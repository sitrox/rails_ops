RailsOps.hookup.draw do
  run 'RailsOps::HookupTest::HookupTarget' do
    on 'RailsOps::HookupTest::HookupStarter'
  end
end
