import joblib
import logging

class MyModel(object):
    """
    Model template. 
    You can load your model parameters in __init__ from a location accessible at runtime.
    """

    def __init__(self):
        """
        Add any initialization parameters. These will be passed at runtime from the graph definition parameters 
        defined in your seldondeployment kubernetes resource manifest.
        """
        logging.info('loading model..')
        self.model = joblib.load('/tmp/model.pkl') 

    def predict(self, X, features_names=None):
        """
        Return a prediction.

        Parameters
        ----------
        X : array-like
        feature_names : array of feature names (optional)
        """
        logging.info('predict request X: %s', X)
        #predictions = self.model.predict(X)
        #return predictions
        return X

