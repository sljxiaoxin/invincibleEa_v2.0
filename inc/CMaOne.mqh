//+------------------------------------------------------------------+
//|                                                   |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.yjx.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018."
#property link      "http://www.yjx.com"

class CMaOne
{  
   private:
      
   public:
   
      string crossType; //none up down
      int crossPass;    //after cross number
      double crossPrice;
      bool isStochCrossOk;
      
      
      CMaOne(){
         crossPass = -1;
         crossPrice = -1;
         crossType = "none"; //up down
         isStochCrossOk = false;
      };
      void AddCol();
      void Reset();
      void SetCross(string ct, double cp);
      bool IsCanOpenBuy();
      bool IsCanOpenSell();
};

void CMaOne::AddCol()
{
   if(crossType != "none"){
      crossPass += 1;
   }
}

void CMaOne::Reset()
{
   crossType = "none";
   crossPrice = -1;
   crossPass = -1;
   crossPrice = -1;
   isStochCrossOk = false;
}

void CMaOne::SetCross(string ct, double cp)
{
   crossType = ct;
   crossPrice = cp;
   crossPass = 0;
   //crossPrice = -1;
   isStochCrossOk = false;
}

bool CMaOne::IsCanOpenBuy()
{
    if(crossType == "up" && isStochCrossOk){
      return true;
    }
    return false;
}


bool CMaOne::IsCanOpenSell()
{
   if(crossType == "down" && isStochCrossOk){
      return true;
    }
    return false;
}
