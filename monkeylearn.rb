require 'monkeylearn'

Monkeylearn.configure do |c|
  c.token = '06daf7c080b41efe1c747997c75b01b8b7a3a1b8'
end
 
r = Monkeylearn.classifiers.detail('cl_ksmgNsh9')
 
positive_category_id = 590992  # Use real category ids, use the classifier detail endpoint
negative_category_id = 590993  # Use real category ids, use the classifier detail endpoint
 
# samples = [
#     ['Nice beatiful', positive_category_id],
#     ['awesome excelent', positive_category_id],
#     ['Awful bad', negative_category_id],
#     ['sad pale', negative_category_id],
#     ['happy sad both multilabel', [positive_category_id, negative_category_id]]
# ]

def monkeylearn_train(samples)
  samples.map! { |x| [x, positive_category_id]}
  r = Monkeylearn.classifiers.upload_samples('cl_ksmgNsh9', samples)
  Monkeylearn.classifiers.train('cl_ksmgNsh9')
  end
