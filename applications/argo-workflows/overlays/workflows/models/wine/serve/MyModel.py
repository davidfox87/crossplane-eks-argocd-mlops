import mlflow.pyfunc

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
        
        model_name = "wine"
        model_version = 2

        self.model = mlflow.pyfunc.load_model(
            model_uri=f"models:/{model_name}/{model_version}"
        )   

    def predict(self, X, features_names=None):
        """
        Return a prediction.

        Parameters
        ----------
        X : array-like
        feature_names : array of feature names (optional)
        """
        predictions = self.model.predict(X)
        return predictions