import importlib
from typing import Any

def lazy_import(mod_name: str) -> Any:
    class Lazy:
        def __getattr__(self, name:str) -> Any:
            module = importlib.import_module(mod_name)
            return getattr(module, name)
    
    return Lazy()
            
